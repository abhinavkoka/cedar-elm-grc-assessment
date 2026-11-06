# Scan digest: baseline-20261026-191650

- Rules in CIS L1 Server profile: **408**
- Results: fail 118, notapplicable 65, pass 225
- Raw pass rate (pass / pass+fail): **65.6%**
- Tailored pass rate (excluding 27 N/A-by-design rules): **66.4%**
- Failed rules: **112** (low 12, medium 90, high 4, unknown 6)
- Failed rules citing HIPAA Security Rule: 12
- Lynis hardening index: **63**, warnings 1, suggestions 51

## Failed rules by NIST SP 800-53 family

| Family | Failed |
|---|---|
| AC Access Control | 48 |
| CM Configuration Management | 24 |
| SC System and Communications Protection | 21 |
| IA Identification and Authentication | 12 |
| SI System and Information Integrity | 3 |
| AU Audit and Accountability | 3 |
| MP Media Protection | 1 |

## Failed rules

| CIS | Rule | Severity | Primary 800-53 | Decision |
|---|---|---|---|---|
| 1.1.1.1 | Disable Mounting of cramfs | low | CM-7(a) | Open |
| 1.1.1.2 | Disable Mounting of freevxfs | low | CM-7(a) | Open |
| 1.1.1.3 | Disable Mounting of hfs | low | CM-7(a) | Open |
| 1.1.1.4 | Disable Mounting of hfsplus | low | CM-7(a) | Open |
| 1.1.1.5 | Disable Mounting of jffs2 | low | CM-7(a) | Open |
| 1.1.1.9 | Disable Modprobe Loading of USB Storage Driver | medium | MP-7 | Open |
| 1.1.2.1.1 | Ensure /tmp Located On Separate Partition | low | SC-5(2) | Deferred to POA&M |
| 1.1.2.2.2 | Add nodev Option to /dev/shm | medium | AC-6 | Open |
| 1.1.2.2.3 | Add nosuid Option to /dev/shm | medium | AC-6 | Open |
| 1.1.2.2.4 | Add noexec Option to /dev/shm | medium | AC-6 | Open |
| 1.3.1.1 | Ensure AppArmor Utils is installed | medium | AC-3(3) | Open |
| 1.3.1.2 | Ensure AppArmor is enabled in the bootloader configuration | medium | AC-3(3) | Open |
| 1.3.1.3 | All AppArmor Profiles are in enforce or complain mode | medium | AC-3(3) | Open |
| 1.4.1 | Set Boot Loader Password in grub2 | high | CM-6(a) | Risk accepted |
| 1.4.1 | Set the UEFI Boot Loader Password | high | CM-6(a) | Risk accepted |
| 1.5.1 | Enable Randomized Layout of Virtual Address Space | medium | SC-30 | Open |
| 1.5.3 | Disable Core Dumps for All Users | medium | SC-7(10) | Open |
| 1.5.3 | Disable Core Dumps for SUID programs | medium | SI-11(a) | Open |
| 1.5.5 | Disable Apport Service | unknown | SI-16 | Open |
| 1.6.2 | Ensure Local Login Warning Banner Is Configured Properly | medium | AC-8 | Open |
| 1.6.3 | Ensure Remote Login Warning Banner Is Configured Properly | medium | AC-8 | Open |
| 2.1.13 | Uninstall rsync Package | medium | CM-7 | Open |
| 2.1.13 | Ensure rsyncd service is disabled | medium | CM-7 | Open |
| 2.1.18 | Uninstall nginx Package | unknown | CM-7(a) | Business exception |
| 2.1.18 | Disable nginx Service | unknown | CM-7 | Business exception |
| 2.2.4 | Remove telnet Clients | low | CM-7 | Open |
| 2.2.4 | Remove telnet Clients | low | CM-7 | Open |
| 2.2.6 | Remove ftp Package | low | CM-7 | Open |
| 2.2.6 | Remove tnftp Package | low | CM-7 | Open |
| 2.3.2.1 | Configure Systemd Timesyncd Servers | medium | AU-8 | Open |
| 2.4.1.2 | Verify Permissions on crontab | medium | AC-6(1) | Open |
| 2.4.1.3 | Verify Permissions on cron.hourly | medium | AC-6(1) | Open |
| 2.4.1.4 | Verify Permissions on cron.daily | medium | AC-6(1) | Open |
| 2.4.1.5 | Verify Permissions on cron.weekly | medium | AC-6(1) | Open |
| 2.4.1.6 | Verify Permissions on cron.monthly | medium | AC-6(1) | Open |
| 2.4.1.7 | Verify Permissions on cron.d | medium | AC-6(1) | Open |
| 2.4.1.8 | Ensure that /etc/cron.allow exists | medium | AC-6 | Open |
| 2.4.2.1 | Ensure that /etc/at.allow exists | medium | AC-6 | Open |
| 3.3.1 | Disable Kernel Parameter for IPv6 Forwarding | medium | CM-6.1(iv) | Open |
| 3.3.1 | Disable Kernel Parameter for IP Forwarding on IPv4 Interfaces | medium | SC-5 | Open |
| 3.3.2 | Disable Kernel Parameter for Sending ICMP Redirects on all IPv4 Interfaces | medium | SC-5 | Open |
| 3.3.2 | Disable Kernel Parameter for Sending ICMP Redirects on all IPv4 Interfaces by Default | medium | SC-5 | Open |
| 3.3.5 | Disable Accepting ICMP Redirects for All IPv6 Interfaces | medium | CM-6.1(iv) | Open |
| 3.3.5 | Disable Kernel Parameter for Accepting ICMP Redirects by Default on IPv6 Interfaces | medium | CM-7(a) | Open |
| 3.3.5 | Disable Accepting ICMP Redirects for All IPv4 Interfaces | medium | SC-7(a) | Open |
| 3.3.5 | Disable Kernel Parameter for Accepting ICMP Redirects by Default on IPv4 Interfaces | medium | SC-7(a) | Open |
| 3.3.6 | Disable Kernel Parameter for Accepting Secure ICMP Redirects on all IPv4 Interfaces | medium | SC-7(a) | Open |
| 3.3.6 | Configure Kernel Parameter for Accepting Secure Redirects By Default | medium | SC-5 | Open |
| 3.3.7 | Enable Kernel Parameter to Use Reverse Path Filtering on all IPv4 Interfaces | medium | SC-7(a) | Open |
| 3.3.7 | Enable Kernel Parameter to Use Reverse Path Filtering on all IPv4 Interfaces by Default | medium | SC-7(a) | Open |
| 3.3.8 | Disable Kernel Parameter for Accepting Source-Routed Packets on all IPv6 Interfaces | medium | CM-7(a) | Open |
| 3.3.8 | Disable Kernel Parameter for Accepting Source-Routed Packets on IPv6 Interfaces by Default | medium | CM-6.1(iv) | Open |
| 3.3.8 | Disable Kernel Parameter for Accepting Source-Routed Packets on all IPv4 Interfaces | medium | SC-5 | Open |
| 3.3.8 | Disable Kernel Parameter for Accepting Source-Routed Packets on IPv4 Interfaces by Default | medium | SC-5 | Open |
| 3.3.9 | Enable Kernel Parameter to Log Martian Packets on all IPv4 Interfaces | unknown | SC-5(3)(a) | Open |
| 3.3.9 | Enable Kernel Parameter to Log Martian Packets on all IPv4 Interfaces by Default | unknown | SC-5(3)(a) | Open |
| 3.3.10 | Enable Kernel Parameter to Use TCP Syncookies on Network Interfaces | medium | SC-5(1) | Open |
| 3.3.11 | Configure Accepting Router Advertisements on All IPv6 Interfaces | medium | CM-7(a) | Open |
| 3.3.11 | Disable Accepting Router Advertisements on all IPv6 Interfaces by Default | medium | CM-7(a) | Open |
| 4.2.3 | Verify ufw Active | medium | SC-7 | Manual remediation |
| 4.2.4 | Set UFW Loopback Traffic | medium | SC-7 | Manual remediation |
| 4.2.6 | Ensure ufw Firewall Rules Exist for All Open Ports | medium | SC-7 | Manual remediation |
| 4.2.7 | Ensure ufw Default Deny Firewall Policy | medium | SC-7 | Manual remediation |
| 5.1.1 | Verify Permissions on SSH Server config file | medium | AC-17(a) | Open |
| 5.1.1 | Verify Permissions on SSH Server Config File | medium | AC-17(a) | Open |
| 5.1.4 | Limit Users' SSH Access | unknown | AC-3 | Manual remediation |
| 5.1.5 | Enable SSH Warning Banner | medium | AC-8(a) | Open |
| 5.1.6 | Use Only Strong Ciphers | medium | AC-17 | Open |
| 5.1.7 | Set SSH Client Alive Count Max | medium | AC-2(5) | Open |
| 5.1.7 | Set SSH Client Alive Interval | medium | AC-17(a) | Open |
| 5.1.10 | Disable Host-Based Authentication | medium | AC-3 | Open |
| 5.1.11 | Disable SSH Support for .rhosts Files | medium | AC-17(a) | Open |
| 5.1.12 | Use Only Strong Key Exchange algorithms | medium | AC-17 | Open |
| 5.1.13 | Ensure SSH LoginGraceTime is configured | medium | AC-17 | Open |
| 5.1.14 | Set LogLevel to INFO | low | AC-17(a) | Open |
| 5.1.15 | Use Only Strong MACs | medium | AC-17 (2) | Open |
| 5.1.16 | Set SSH authentication attempt limit | medium | AC-17 | Open |
| 5.1.17 | Set SSH MaxSessions limit | medium | AC-17 | Open |
| 5.1.18 | Ensure SSH MaxStartups is configured | medium | AC-17 | Open |
| 5.1.19 | Disable SSH Access via Empty Passwords | high | AC-17(a) | Open |
| 5.1.20 | Disable SSH Root Login | medium | AC-6(2) | Open |
| 5.1.21 | Do Not Allow SSH Environment Options | medium | AC-17(a) | Open |
| 5.2.3 | Ensure Sudo Logfile Exists - sudo logfile | low | AC-6(2) | Open |
| 5.2.6 | Require Re-Authentication When Using the sudo Command | medium | IA-11 | Open |
| 5.2.7 | Ensure the Group Used by pam_wheel.so Module Exists on System and is Empty | medium | AC-6(2) | Open |
| 5.2.7 | Enforce Usage of pam_wheel with Group Parameter for su Authentication | medium | AC-6(2) | Open |
| 5.3.1.3 | Install pam_pwquality Package | medium | IA-5(1) | Open |
| 5.3.2.2 | Ensure pam_faillock module is enabled | medium | IA-5(1) | Open |
| 5.3.2.3 | Verify pam_pwquality module is activated | medium | IA-5(1) | Open |
| 5.3.2.4 | Verify pam_pwhistory module is activated | medium | IA-5(1) | Open |
| 5.3.3.1.1 | Lock Accounts After Failed Password Attempts | medium | AC-7(a) | Open |
| 5.3.3.1.2 | Set Lockout Time for Failed Password Attempts | medium | AC-7(b) | Open |
| 5.3.3.3.1 | Limit Password Reuse | medium | IA-5(1) | Open |
| 5.3.3.3.2 | Limit Password Reuse | medium | IA-5(1) | Open |
| 5.3.3.3.3 | Enforce Password History with use_authtok | medium | IA-5(1) | Open |
| 5.3.3.4.1 | Prevent Login to Accounts With Empty Password | high | IA-5(1) | Open |
| 5.4.1.1 | Set Password Maximum Age | medium | IA-5(f) | Open |
| 5.4.1.1 | Set Existing Passwords Maximum Age | medium | IA-5(f) | Open |
| 5.4.1.5 | Set Account Expiration Following Inactivity | medium | IA-4(e) | Open |
| 5.4.2.5 | Ensure that All Entries in The Path of Root Are Directories | medium | AC-2 | Open |
| 5.4.2.7 | Ensure that System Accounts Do Not Run a Shell Upon Login | medium | AC-6 | Open |
| 5.4.3.2 | Set Interactive Session Timeout | medium | AC-12 | Open |
| 5.4.3.3 | Ensure the Default Bash Umask is Set Correctly | medium | AC-6(1) | Open |
| 5.4.3.3 | Ensure the Default Umask is Set Correctly in login.defs | medium | AC-6(1) | Open |
| 5.4.3.3 | Ensure the Default Umask is Set Correctly in /etc/profile | medium | AC-6(1) | Open |
| 6.1.3.3 | Ensure journald is configured to send logs to rsyslog | medium | AU-9 | Open |
| 6.1.4.1 | Verify permissions of log files | medium | SI-11(a) | Open |
| 6.1.4.1 | Verify ownership of log files | medium | AU-9 | Open |
| 6.3.1 | Install AIDE | medium | CM-6(a) | Open |
| 6.3.1 | Build and Test AIDE Database | medium | CM-6(a) | Open |
| 7.1.11 | Ensure No World-Writable Files Exist | medium | AC-6(1) | Open |
| 7.2.10 | Ensure All User Initialization Files Have Mode 0740 Or Less Permissive | medium | AC-2 | Open |

## Lynis warnings

- `FIRE-4512` iptables module(s) loaded, but no rules active
