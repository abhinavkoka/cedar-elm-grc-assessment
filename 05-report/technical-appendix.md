# Technical appendix

Supporting detail for the assessment report. The report states the findings and results. This file holds the identifiers, versions and evidence references behind them. All testing was performed on a lab replica of the intake server, not on a real organization's production system, and all patient data is fabricated.

## A. Test environment and tools

| Item | Detail |
|---|---|
| Target | cedar-intake01, Ubuntu 24.04.5 LTS VM (lab replica) |
| Baseline scan | October 26, 2026, 19:16 UTC |
| Remediation | October 26, 2026, 19:30 to 19:54 UTC (24 minutes), change record CR-20261026-193009, VM snapshot taken first as the rollback plan |
| Post-remediation scan | October 26, 2026, 20:38 UTC, after a reboot |
| OpenSCAP | 1.3.9 |
| ComplianceAsCode content | v0.1.82 (SHA-256 in `toolchain.txt`) |
| Lynis | 3.0.9 |
| Manual checks | 13 (MC-01 to MC-13) |

## B. Baseline detail

| Metric | Baseline |
|---|---|
| Rules in the CIS L1 Server profile | 408 |
| Pass / fail / not applicable | 225 / 118 / 65 |
| Raw pass rate (pass / pass + fail) | 65.6% |
| Tailored pass rate (excluding 27 N/A-by-design rules) | 66.4% |
| Failed rules, excluding N/A by design | 112 (4 high, 90 medium, 12 low, 6 unrated) |
| Failed rules citing the HIPAA Security Rule | 12 |
| Lynis hardening index | 63 (1 warning, 51 suggestions) |

Failed rules by NIST SP 800-53 family: Access Control 48, Configuration Management 24, System and Communications Protection 21, Identification and Authentication 12, System and Information Integrity 3, Audit and Accountability 3, Media Protection 1.

High-severity failures: two bootloader-password rules, and two rules allowing empty passwords (SSH and local accounts).

## C. Findings and evidence

| Finding | Seeded condition | Evidence | Verification of closure |
|---|---|---|---|
| TF-01 Contractor account | AF-1 | MC-01, MC-03 | Locked, expired 1970-01-01, shell `nologin`, removed from `sudo` |
| TF-02 SSH | AF-2 | MC-04, CIS 5.1 (19 failures), CIS 5.1.19, 5.3.3.4.1 (empty passwords) | Root login off, `AllowUsers` set, `MaxAuthTries 4`, banner on. Password authentication remains because no key is enrolled (POAM-05) |
| TF-03 ePHI permissions | AF-3 | MC-08 | `drwxr-x--- intake:www-data`, 0 world-writable files |
| TF-04 Host firewall | | MC-05, MC-06, CIS 4.2 | UFW active, default deny both directions, only ports 443 and 22 open inbound |
| TF-05 PostgreSQL exposure | AF-4 | MC-05, MC-07 | Listens on `127.0.0.1:5432` only, remote rule removed |
| TF-06 Audit logging | | MC-13 | auditd active with 9 rules watching ePHI, identity and privileged configuration paths |
| TF-07 Updates | AF-5 | MC-09 | 0 pending updates, `Unattended-Upgrade "1"` |
| TF-08 Kernel parameters | | CIS 3.3 | Network kernel parameters, logging and system maintenance went from 28 failures to 0 |
| TF-09 File integrity | | CIS 6.3 | AIDE installed. Lynis and OpenSCAP disagree about the AIDE database (POAM-26) |

## D. Before and after

| Metric | Baseline | Post | Change |
|---|---|---|---|
| Tailored pass rate | 66.4% | 93.4% | +27.0 pts |
| Raw pass rate | 65.6% | 92.2% | +26.6 pts |
| Failed rules (excl. N/A by design) | 112 | 23 | -89 |
| Open failures (no approved exception) | 108 | 19 | -89 |
| High-severity failures | 4 | 2 (both risk-accepted) | -2 |
| Failed rules citing HIPAA | 12 | 2 (both risk-accepted) | -10 |
| Lynis hardening index | 63 | 74 | +11 |
| Pending package updates | 27 | 0 | -27 |
| World-writable ePHI files | 60 | 0 | -60 |

105 rules were remediated, 13 still fail (5 of them N/A by design) and 2 regressed. A further 13 rules only became applicable after remediation and now fail (see section F).

## E. Baseline decisions (57 rules)

Recorded in `02-technical-audit/remediation/baseline-decisions.csv`.

| Decision | Count | Notes |
|---|---|---|
| N/A by design | 27 | Alternatives the server doesn't use: UFW instead of nftables and iptables, timesyncd instead of chrony, rsyslog instead of journald remote upload |
| Deferred | 17 | Separate partitions need a rebuild (POAM-09) |
| Manual remediation | 9 | SSH user restriction and firewall rules need environment-specific values |
| Business exception | 2 | nginx is required (CIS 2.1.18) |
| Risk accepted | 2 | Bootloader password, with a restricted hypervisor console as the compensating control |

## F. Items found by the verification scan

| Item | Rule or reference | Tracking |
|---|---|---|
| Postfix installed as a dependency of the file-integrity tooling and listening on port 25 on all interfaces | CIS 2.1.21, also flagged by Lynis as MAIL-8818 | POAM-24 |
| `/etc/cron.allow` created with the wrong group owner | CIS 2.4.1.8 | POAM-24 |
| 12 password-quality rules skipped as N/A because the module was installed mid-run | CIS password-quality rules | POAM-25 |
| nginx default site on port 80 (blocked by the firewall), AppArmor profile modes, root PATH entry, Lynis/OpenSCAP disagreement about the AIDE database | CIS 4.2.6, 1.3.1.3, 5.4.2.5 | POAM-26 |

OpenSCAP remediation runs in a single pass and doesn't revisit rules affected by later fixes, which is why these were only caught by the re-scan. A second remediation pass and re-scan is planned for November 2026.

## G. Evidence index

| Evidence | Location |
|---|---|
| Baseline scan (XCCDF, HTML report, Lynis, manual checks, parsed findings) | `02-technical-audit/results/baseline-20261026-191650/` |
| Post-remediation scan and before and after delta | `02-technical-audit/results/post-20261026-203807/` (`delta.csv`, `delta.md`) |
| Evidence bundles and SHA-256 hashes | `02-technical-audit/results/*.tar.gz`, `SHA256SUMS` |
| Change record with post-implementation notes | `02-technical-audit/remediation/change-record-20261026-193009.md` |
| Baseline decisions and post-remediation dispositions | `02-technical-audit/remediation/*.csv` |
| Risk register, heat maps, CSF profile | `03-risk-assessment/cedar-elm-risk-register.xlsx` |
| POA&M (26 items: 4 verified, 3 in progress, 19 open) | `03-risk-assessment/cedar-elm-poam.xlsx` |
| Vendor assessment | `04-vendor-risk/` |

## H. Lesson learned

My SSH session dropped when the host firewall came on. The remediation script finished every step anyway, and I confirmed that after reconnecting. Next time I would apply firewall changes from the hypervisor console or with a scheduled rollback.
