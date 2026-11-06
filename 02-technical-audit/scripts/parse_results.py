#!/usr/bin/env python3
"""
parse_results.py <evidence_dir>

Turns raw scanner output into assessment-ready data:
  findings.csv          one row per CIS rule: result, severity, CIS ref,
                        NIST SP 800-53 controls, HIPAA citations, baseline decision
  summary.json          counts, compliance rates, breakdowns, Lynis index
  findings-summary.md   readable digest for the report

Baseline decisions (N/A by design, business exceptions, risk acceptances,
deferrals) come from ../remediation/baseline-decisions.csv so that the
compliance rate reflects the organization's approved, tailored baseline,
while the raw rate is still reported for transparency.
"""
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from lxml import etree

X = "{http://checklists.nist.gov/xccdf/1.2}"
PREFIX = "xccdf_org.ssgproject.content_rule_"

CIS_SECTIONS = {
    "1": "Initial Setup", "2": "Services", "3": "Network",
    "4": "Host-Based Firewall", "5": "Access Control",
    "6": "Logging and Auditing", "7": "System Maintenance",
}
CIS_SUBSECTIONS = {
    "1.1": "Filesystem", "1.3": "Mandatory Access Control (AppArmor)",
    "1.4": "Bootloader", "1.5": "Process Hardening", "1.6": "Warning Banners",
    "1.7": "GNOME Display Manager", "2.1": "Server Services", "2.2": "Client Services",
    "2.3": "Time Synchronization", "2.4": "Job Schedulers", "3.1": "Network Devices",
    "3.3": "Network Kernel Parameters", "4.1": "Firewall Utility", "4.2": "UFW",
    "4.3": "nftables", "4.4": "iptables", "5.1": "SSH Server", "5.2": "Privilege Escalation (sudo)",
    "5.3": "PAM", "5.4": "User Accounts and Environment", "6.1": "System Logging",
    "6.3": "File Integrity (AIDE)", "7.1": "System File Permissions",
    "7.2": "Local User and Group Settings",
}
NIST_FAMILIES = {
    "AC": "Access Control", "AU": "Audit and Accountability", "CM": "Configuration Management",
    "IA": "Identification and Authentication", "SC": "System and Communications Protection",
    "SI": "System and Information Integrity", "MP": "Media Protection", "CP": "Contingency Planning",
    "MA": "Maintenance", "PE": "Physical and Environmental Protection", "RA": "Risk Assessment",
    "SA": "System and Services Acquisition", "IR": "Incident Response", "PL": "Planning",
}
# Assessor mapping by CIS subsection: (fallback NIST SP 800-53 control, CSF 2.0 subcategory).
# The 800-53 value is used only when the SCAP content provides no 800-53 reference.
SUBSECTION_MAP = {
    "1.1": ("CM-6", "PR.PS-01"), "1.3": ("AC-3(3)", "PR.PS-01"), "1.4": ("AC-3", "PR.AA-05"),
    "1.5": ("SI-16", "PR.PS-01"), "1.6": ("AC-8", "PR.PS-01"), "1.7": ("CM-7", "PR.PS-01"),
    "2.1": ("CM-7", "PR.PS-01"), "2.2": ("CM-7", "PR.PS-01"), "2.3": ("AU-8", "PR.PS-04"),
    "2.4": ("AC-6", "PR.AA-05"), "3.1": ("CM-7", "PR.IR-01"), "3.3": ("SC-7", "PR.IR-01"),
    "4.1": ("SC-7", "PR.IR-01"), "4.2": ("SC-7", "PR.IR-01"), "4.3": ("SC-7", "PR.IR-01"),
    "4.4": ("SC-7", "PR.IR-01"), "5.1": ("AC-17", "PR.AA-03"), "5.2": ("AC-6(2)", "PR.AA-05"),
    "5.3": ("IA-5(1)", "PR.AA-03"), "5.4": ("AC-2", "PR.AA-01"), "6.1": ("AU-9", "PR.PS-04"),
    "6.3": ("SI-7", "DE.CM-09"), "7.1": ("AC-3", "PR.AA-05"), "7.2": ("AC-2", "PR.AA-01"),
}
# Catch-all configuration controls; used as primary only if nothing more specific exists.
GENERIC = {"CM-6", "CM-6(a)", "CM-6(b)", "CM-6(c)", "CM-7(a)", "CM-7(b)"}


def ref_texts(rule, needle):
    return [r.text.strip() for r in rule.findall(X + "reference")
            if needle in (r.get("href") or "") and r.text]


def cis_key(ref):
    return [int(p) if p.isdigit() else 0 for p in ref.split(".")] if ref else [999]


def load_decisions(evidence_dir):
    path = Path(__file__).resolve().parent.parent / "remediation" / "baseline-decisions.csv"
    if not path.exists():
        return {}
    with open(path, newline="") as f:
        return {row["rule_id"].strip(): row for row in csv.DictReader(f)}


def parse_lynis(path):
    out = {"hardening_index": None, "warnings": [], "suggestions": []}
    if not path.exists():
        return out
    for line in path.read_text(errors="replace").splitlines():
        if line.startswith("hardening_index="):
            out["hardening_index"] = int(line.split("=", 1)[1])
        elif line.startswith("warning[]="):
            p = line.split("=", 1)[1].split("|")
            out["warnings"].append({"id": p[0], "text": p[1] if len(p) > 1 else ""})
        elif line.startswith("suggestion[]="):
            p = line.split("=", 1)[1].split("|")
            out["suggestions"].append({"id": p[0], "text": p[1] if len(p) > 1 else ""})
    return out


def main(evidence_dir):
    ev = Path(evidence_dir)
    tree = etree.parse(str(ev / "xccdf-results.xml"))
    rules = {r.get("id"): r for r in tree.iter(X + "Rule")}
    test = next(tree.iter(X + "TestResult"))
    decisions = load_decisions(ev)

    rows = []
    for rr in test.findall(X + "rule-result"):
        rid = rr.get("idref")
        result = rr.find(X + "result").text
        if result == "notselected":
            continue
        rule = rules.get(rid)
        short = rid.replace(PREFIX, "")
        title = rule.find(X + "title").text.strip() if rule is not None else short
        cis = ref_texts(rule, "cisecurity.org/benchmark") if rule is not None else []
        nist = ref_texts(rule, "800-53") if rule is not None else []
        hipaa = ref_texts(rule, "CFR") if rule is not None else []
        csf = ref_texts(rule, "CSWP") if rule is not None else []
        cis_ref = cis[0] if cis else ""
        top = cis_ref.split(".")[0] if cis_ref else ""
        sub = ".".join(cis_ref.split(".")[:2]) if cis_ref else ""
        fallback, csf2 = SUBSECTION_MAP.get(sub, ("", ""))
        specific = [c for c in nist if c not in GENERIC]
        primary = (specific or nist or [""])[0]
        mapping_source = "SCAP content" if primary else ("Assessor (by CIS section)" if fallback else "")
        primary = primary or fallback
        family = re.match(r"[A-Z]{2}", primary).group(0) if primary else ""
        d = decisions.get(short, {})
        rows.append({
            "rule_id": short, "title": title, "severity": rr.get("severity") or
            (rule.get("severity") if rule is not None else "unknown"),
            "result": result, "cis_ref": cis_ref,
            "cis_section": f"{top} {CIS_SECTIONS.get(top, '')}".strip(),
            "cis_subsection": f"{sub} {CIS_SUBSECTIONS.get(sub, '')}".strip(),
            "nist_800_53_rev4": "; ".join(nist), "primary_control": primary,
            "control_family": family, "mapping_source": mapping_source,
            "csf_2_0": csf2, "hipaa": "; ".join(hipaa),
            "csf_1_1": "; ".join(csf),
            "decision": d.get("decision", ""), "decision_rationale": d.get("rationale", ""),
            "poam_id": d.get("poam_id", ""),
        })
    rows.sort(key=lambda r: cis_key(r["cis_ref"]))

    with open(ev / "findings.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    by_result = Counter(r["result"] for r in rows)
    na_design = [r for r in rows if r["decision"] == "N/A by design"]
    scored = [r for r in rows if r["result"] in ("pass", "fail")]
    scored_adj = [r for r in scored if r["decision"] != "N/A by design"]
    fails = [r for r in scored_adj if r["result"] == "fail"]
    open_fails = [r for r in fails if r["decision"] not in
                  ("Business exception", "Risk accepted")]

    def rate(rs):
        return round(100 * sum(r["result"] == "pass" for r in rs) / len(rs), 1) if rs else None

    lynis = parse_lynis(ev / "lynis-report.dat")
    summary = {
        "label": ev.name,
        "rules_in_profile": len(rows),
        "results": dict(by_result),
        "raw_pass_rate_pct": rate(scored),
        "tailored_pass_rate_pct": rate(scored_adj),
        "not_applicable_by_design": len(na_design),
        "failed_rules": len(fails),
        "failed_by_severity": dict(Counter(r["severity"] for r in fails)),
        "failed_by_cis_section": dict(Counter(r["cis_section"] for r in fails)),
        "failed_by_cis_subsection": dict(Counter(r["cis_subsection"] for r in fails)),
        "failed_by_800_53_family": {
            f"{k} {NIST_FAMILIES.get(k, '')}".strip(): v
            for k, v in Counter(r["control_family"] for r in fails).most_common()},
        "failed_by_csf_2_0": dict(Counter(r["csf_2_0"] for r in fails).most_common()),
        "failed_with_hipaa_citation": sum(bool(r["hipaa"]) for r in fails),
        "failed_with_accepted_exception": len(fails) - len(open_fails),
        "open_failed_rules": len(open_fails),
        "lynis_hardening_index": lynis["hardening_index"],
        "lynis_warnings": lynis["warnings"],
        "lynis_suggestion_count": len(lynis["suggestions"]),
    }
    (ev / "summary.json").write_text(json.dumps(summary, indent=2))

    # Readable digest
    md = [f"# Scan digest: {ev.name}", "",
          f"- Rules in CIS L1 Server profile: **{len(rows)}**",
          f"- Results: " + ", ".join(f"{k} {v}" for k, v in sorted(by_result.items())),
          f"- Raw pass rate (pass / pass+fail): **{summary['raw_pass_rate_pct']}%**",
          f"- Tailored pass rate (excluding {len(na_design)} N/A-by-design rules): "
          f"**{summary['tailored_pass_rate_pct']}%**",
          f"- Failed rules: **{len(fails)}** "
          f"({', '.join(f'{k} {v}' for k, v in summary['failed_by_severity'].items())})",
          f"- Failed rules citing HIPAA Security Rule: {summary['failed_with_hipaa_citation']}",
          f"- Lynis hardening index: **{lynis['hardening_index']}**, "
          f"warnings {len(lynis['warnings'])}, suggestions {len(lynis['suggestions'])}", "",
          "## Failed rules by NIST SP 800-53 family", "",
          "| Family | Failed |", "|---|---|"]
    md += [f"| {k} | {v} |" for k, v in summary["failed_by_800_53_family"].items()]
    md += ["", "## Failed rules", "",
           "| CIS | Rule | Severity | Primary 800-53 | Decision |", "|---|---|---|---|---|"]
    md += [f"| {r['cis_ref']} | {r['title']} | {r['severity']} | {r['primary_control']} | "
           f"{r['decision'] or 'Open'} |" for r in fails]
    if lynis["warnings"]:
        md += ["", "## Lynis warnings", ""] + [f"- `{w['id']}` {w['text']}" for w in lynis["warnings"]]
    (ev / "findings-summary.md").write_text("\n".join(md) + "\n")

    print(f"{ev.name}: {len(rows)} rules | pass {by_result.get('pass', 0)} | "
          f"fail {by_result.get('fail', 0)} | tailored pass rate "
          f"{summary['tailored_pass_rate_pct']}% | Lynis {lynis['hardening_index']}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
