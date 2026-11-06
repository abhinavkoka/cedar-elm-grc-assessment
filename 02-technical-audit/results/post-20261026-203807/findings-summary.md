# Scan digest: post-20261026-203807

- Rules in CIS L1 Server profile: **408**
- Results: fail 28, notapplicable 51, pass 329
- Raw pass rate (pass / pass+fail): **92.2%**
- Tailored pass rate (excluding 27 N/A-by-design rules): **93.4%**
- Failed rules: **23** (low 1, medium 18, high 2, unknown 2)
- Failed rules citing HIPAA Security Rule: 2
- Lynis hardening index: **74**, warnings 2, suggestions 48

## Failed rules by NIST SP 800-53 family

| Family | Failed |
|---|---|
| IA Identification and Authentication | 12 |
| CM Configuration Management | 6 |
| AC Access Control | 3 |
| SC System and Communications Protection | 2 |

## Failed rules

| CIS | Rule | Severity | Primary 800-53 | Decision |
|---|---|---|---|---|
| 1.1.2.1.1 | Ensure /tmp Located On Separate Partition | low | SC-5(2) | Deferred to POA&M |
| 1.3.1.3 | All AppArmor Profiles are in enforce or complain mode | medium | AC-3(3) | Open |
| 1.4.1 | Set Boot Loader Password in grub2 | high | CM-6(a) | Risk accepted |
| 1.4.1 | Set the UEFI Boot Loader Password | high | CM-6(a) | Risk accepted |
| 2.1.18 | Uninstall nginx Package | unknown | CM-7(a) | Business exception |
| 2.1.18 | Disable nginx Service | unknown | CM-7 | Business exception |
| 2.1.21 | Ensure Mail Transfer Agent is not Listening on any non-loopback Address | medium | CM-7 | Open |
| 2.1.21 | Disable Postfix Network Listening | medium | CM-7(a) | Open |
| 2.4.1.8 | Verify Group Who Owns /etc/cron.allow file | medium | AC-6(1) | Open |
| 4.2.6 | Ensure ufw Firewall Rules Exist for All Open Ports | medium | SC-7 | Manual remediation |
| 5.3.3.2.1 | Ensure PAM Enforces Password Requirements - Minimum Different Characters | medium | IA-5(c) | Open |
| 5.3.3.2.2 | Ensure PAM Enforces Password Requirements - Minimum Length | medium | IA-5(c) | Open |
| 5.3.3.2.3 | Ensure PAM Enforces Password Requirements - Minimum Digit Characters | medium | IA-5(c) | Open |
| 5.3.3.2.3 | Ensure PAM Enforces Password Requirements - Minimum Lowercase Characters | medium | IA-5(c) | Open |
| 5.3.3.2.3 | Ensure PAM Enforces Password Requirements - Minimum Different Categories | medium | IA-5(c) | Open |
| 5.3.3.2.3 | Ensure PAM Enforces Password Requirements - Minimum Special Characters | medium | IA-5(c) | Open |
| 5.3.3.2.3 | Ensure PAM Enforces Password Requirements - Minimum Uppercase Characters | medium | IA-5(c) | Open |
| 5.3.3.2.4 | Set Password Maximum Consecutive Repeating Characters | medium | IA-5(c) | Open |
| 5.3.3.2.5 | Limit the maximum number of sequential characters in passwords | medium | IA-5(1) | Open |
| 5.3.3.2.6 | Ensure PAM Enforces Password Requirements - Prevent the Use of Dictionary Words | medium | IA-5(c) | Open |
| 5.3.3.2.7 | Ensure PAM Enforces Password Requirements - Enforcing | medium | IA-5(1) | Open |
| 5.3.3.2.8 | Ensure PAM Enforces Password Requirements - Enforce for root User | medium | IA-5(c) | Open |
| 5.4.2.5 | Ensure that All Entries in The Path of Root Are Directories | medium | AC-2 | Open |

## Lynis warnings

- `MAIL-8818` Found some information disclosure in SMTP banner (OS or software name)
- `FINT-4316` No AIDE database was found, needed for AIDE functionality
