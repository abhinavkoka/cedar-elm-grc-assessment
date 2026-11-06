# Before / after: cedar-intake01

| Metric | Baseline | Post-remediation | Change |
|---|---|---|---|
| Tailored pass rate (%) | 66.4 | 93.4 | +27.0 |
| Raw pass rate (%) | 65.6 | 92.2 | +26.6 |
| Failed rules | 112 | 23 | -89 |
| Open failed rules (no approved exception) | 108 | 19 | -89 |
| Lynis hardening index | 63 | 74 | +11 |
| High-severity failures | 4 | 2 | -2 |

Rule outcomes: 105 remediated, 13 still failing, 2 regressed.

## Still failing after remediation

| CIS | Rule | Severity | Disposition | POA&M |
|---|---|---|---|---|
| 1.1.2.1.1 | Ensure /tmp Located On Separate Partition | low | Deferred to POA&M | POAM-09 |
| 1.3.1.3 | All AppArmor Profiles are in enforce or complain mode | medium | Open - add to POA&M |  |
| 1.4.1 | Set the UEFI Boot Loader Password | high | Risk accepted |  |
| 1.4.1 | Set Boot Loader Password in grub2 | high | Risk accepted |  |
| 2.1.18 | Disable nginx Service | unknown | Business exception |  |
| 2.1.18 | Uninstall nginx Package | unknown | Business exception |  |
| 4.2.6 | Ensure ufw Firewall Rules Exist for All Open Ports | medium | Manual remediation |  |
| 4.3.2 | Remove ufw Package | medium | N/A by design |  |
| 4.3.4 | Ensure a Table Exists for Nftables | medium | N/A by design |  |
| 4.3.6 | Set nftables Configuration for Loopback Traffic | medium | N/A by design |  |
| 4.3.9 | Verify nftables Service is Enabled | medium | N/A by design |  |
| 4.3.10 | Ensure nftables Rules are Permanent | medium | N/A by design |  |
| 5.4.2.5 | Ensure that All Entries in The Path of Root Are Directories | medium | Open - add to POA&M |  |

## Regressions (investigate)

- 2.1.21 Ensure Mail Transfer Agent is not Listening on any non-loopback Address
- 2.4.1.8 Verify Group Who Owns /etc/cron.allow file
