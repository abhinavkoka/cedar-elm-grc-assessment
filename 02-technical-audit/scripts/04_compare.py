#!/usr/bin/env python3
"""
04_compare.py <baseline_evidence_dir> <post_evidence_dir>

Compares two parsed scans (findings.csv + summary.json produced by
parse_results.py) and writes, into the post directory:
  delta.csv   rule-level before/after with status: Remediated, Still failing,
              Regressed, Unchanged pass, Other
  delta.md    before/after metrics table for the report
"""
import csv
import json
import sys
from collections import Counter
from pathlib import Path


def load(d):
    d = Path(d)
    with open(d / "findings.csv", newline="") as f:
        rows = {r["rule_id"]: r for r in csv.DictReader(f)}
    return rows, json.loads((d / "summary.json").read_text())


def main(base_dir, post_dir):
    before, sb = load(base_dir)
    after, sa = load(post_dir)
    out = []
    for rid in before.keys() | after.keys():
        b, a = before.get(rid, {}), after.get(rid, {})
        rb, ra = b.get("result", "absent"), a.get("result", "absent")
        if rb == "fail" and ra == "pass":
            status = "Remediated"
        elif rb == "fail" and ra == "fail":
            status = "Still failing"
        elif rb == "pass" and ra == "fail":
            status = "Regressed"
        elif rb == "pass" and ra == "pass":
            status = "Unchanged pass"
        else:
            status = "Other"
        src = a or b
        out.append({
            "rule_id": rid, "title": src.get("title", ""), "cis_ref": src.get("cis_ref", ""),
            "severity": src.get("severity", ""), "before": rb, "after": ra, "status": status,
            "primary_control": src.get("primary_control", ""), "csf_2_0": src.get("csf_2_0", ""),
            "decision": src.get("decision", ""), "poam_id": src.get("poam_id", ""),
        })
    out.sort(key=lambda r: [int(p) if p.isdigit() else 0 for p in r["cis_ref"].split(".")] or [999])
    post = Path(post_dir)
    with open(post / "delta.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        w.writerows(out)

    st = Counter(r["status"] for r in out)
    still = [r for r in out if r["status"] == "Still failing"]
    regressed = [r for r in out if r["status"] == "Regressed"]

    def fmt(v):
        return "n/a" if v is None else v

    md = ["# Before / after: cedar-intake01", "",
          "| Metric | Baseline | Post-remediation | Change |", "|---|---|---|---|"]
    for label, key in [("Tailored pass rate (%)", "tailored_pass_rate_pct"),
                       ("Raw pass rate (%)", "raw_pass_rate_pct"),
                       ("Failed rules", "failed_rules"),
                       ("Open failed rules (no approved exception)", "open_failed_rules"),
                       ("Lynis hardening index", "lynis_hardening_index")]:
        x, y = sb.get(key), sa.get(key)
        ch = round(y - x, 1) if isinstance(x, (int, float)) and isinstance(y, (int, float)) else ""
        md.append(f"| {label} | {fmt(x)} | {fmt(y)} | {'+' if isinstance(ch, (int, float)) and ch > 0 else ''}{ch} |")
    bh = sb.get("failed_by_severity", {}).get("high", 0)
    ah = sa.get("failed_by_severity", {}).get("high", 0)
    md.append(f"| High-severity failures | {bh} | {ah} | {ah - bh:+d} |")
    md += ["", f"Rule outcomes: {st.get('Remediated', 0)} remediated, "
           f"{st.get('Still failing', 0)} still failing, {st.get('Regressed', 0)} regressed.", ""]
    if still:
        md += ["## Still failing after remediation", "",
               "| CIS | Rule | Severity | Disposition | POA&M |", "|---|---|---|---|---|"]
        md += [f"| {r['cis_ref']} | {r['title']} | {r['severity']} | "
               f"{r['decision'] or 'Open - add to POA&M'} | {r['poam_id']} |" for r in still]
    if regressed:
        md += ["", "## Regressions (investigate)", ""] + \
              [f"- {r['cis_ref']} {r['title']}" for r in regressed]
    (post / "delta.md").write_text("\n".join(md) + "\n")
    print("\n".join(md[:12]))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
