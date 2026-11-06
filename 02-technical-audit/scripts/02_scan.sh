#!/usr/bin/env bash
# =============================================================================
# 02_scan.sh <label>
# Collects assessment evidence from cedar-intake01:
#   1. OpenSCAP evaluation against CIS Ubuntu 24.04 Level 1 - Server
#   2. Lynis system audit (independent second tool)
#   3. Manual configuration checks (accounts, SSH, services, data, patching)
#   4. Parses results into findings.csv / summary.json
# Output is bundled as evidence-<label>-<timestamp>.tar.gz
#
#   sudo bash 02_scan.sh baseline     # before remediation
#   sudo bash 02_scan.sh post         # after remediation
# =============================================================================
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }
LABEL="${1:?usage: 02_scan.sh <baseline|post>}"

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS=/opt/cedar-audit
DS="$TOOLS/ssg-ubuntu2404-ds.xml"
PROFILE=xccdf_org.ssgproject.content_profile_cis_level1_server
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$HERE/../results/$LABEL-$STAMP"
mkdir -p "$OUT"
[[ -f "$DS" ]] || { echo "Run 01_install_tools.sh first." >&2; exit 1; }

echo "[1/4] OpenSCAP: CIS Level 1 Server (2-5 minutes)..."
oscap xccdf eval --profile "$PROFILE" \
  --results "$OUT/xccdf-results.xml" \
  --report  "$OUT/oscap-report.html" \
  "$DS" > "$OUT/oscap-stdout.txt" 2> "$OUT/oscap-stderr.txt"
rc=$?   # 0 = all pass, 2 = at least one rule failed (expected), 1 = error
[[ $rc -eq 1 ]] && { echo "oscap returned an error; see $OUT/oscap-stderr.txt" >&2; exit 1; }

echo "[2/4] Lynis system audit (1-2 minutes)..."
lynis audit system --quick --no-colors \
  --report-file "$OUT/lynis-report.dat" --logfile "$OUT/lynis.log" > "$OUT/lynis-stdout.txt" 2>&1

echo "[3/4] Manual configuration checks..."
M="$OUT/manual-checks.txt"
section() { printf '\n===== %s =====\n' "$1" >> "$M"; }
{
  echo "Host: $(hostname)   Collected: $(date -Is)   Label: $LABEL"
  . /etc/os-release; echo "OS: $PRETTY_NAME   Kernel: $(uname -r)"
} > "$M"

section "MC-01 Interactive accounts (UID >= 1000) and last login"
awk -F: '$3>=1000 && $3<65534 {print $1, "uid="$3, "shell="$7, "gecos="$5}' /etc/passwd >> "$M"
lastlog -u 1000-60000 >> "$M" 2>&1
section "MC-02 Account lock/expiry status"
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
  printf '%s: %s | expires: %s\n' "$u" "$(passwd -S "$u" | awk '{print $2}')" \
    "$(chage -l "$u" | awk -F': ' '/Account expires/ {print $2}')" >> "$M"
done
section "MC-03 Privileged group membership (sudo, adm)"
getent group sudo adm >> "$M"
section "MC-04 Effective SSH daemon settings"
sshd -T 2>/dev/null | grep -Ei '^(passwordauthentication|permitrootlogin|pubkeyauthentication|maxauthtries|allowusers|allowgroups|clientaliveinterval|logingracetime|x11forwarding|banner) ' >> "$M"
section "MC-05 Listening network services"
ss -tulpnH >> "$M"
section "MC-06 Host firewall"
(ufw status verbose 2>&1 || echo "ufw not installed") >> "$M"
section "MC-07 PostgreSQL network exposure"
sudo -u postgres psql -tAc "SHOW listen_addresses" >> "$M" 2>&1
grep -Ev '^\s*(#|$)' /etc/postgresql/*/main/pg_hba.conf >> "$M" 2>&1
section "MC-08 ePHI data store permissions (/srv/intake/uploads)"
stat -c '%A %U:%G %n' /srv/intake/uploads >> "$M" 2>&1
echo "world-writable files: $(find /srv/intake/uploads -type f -perm -0002 | wc -l)" >> "$M"
echo "total files: $(find /srv/intake/uploads -type f | wc -l)" >> "$M"
section "MC-09 Patch status"
apt-get update -qq >/dev/null 2>&1
echo "upgradable packages: $(apt list --upgradable 2>/dev/null | grep -c upgradable)" >> "$M"
echo "security updates pending: $(apt list --upgradable 2>/dev/null | grep -c -- '-security')" >> "$M"
grep -h Unattended /etc/apt/apt.conf.d/20auto-upgrades >> "$M" 2>&1
section "MC-10 Running services"
systemctl list-units --type=service --state=running --no-legend --plain | awk '{print $1}' >> "$M"
section "MC-11 TLS certificate on portal"
openssl x509 -in /etc/nginx/tls/intake.crt -noout -subject -issuer -enddate >> "$M" 2>&1
section "MC-12 Remote log forwarding"
(grep -rhE '^\s*[^#].*@@?' /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null || echo "no rsyslog forwarding configured") >> "$M"

section "MC-13 Audit daemon (HIPAA 164.312(b))"
(systemctl is-active auditd 2>/dev/null || echo "auditd not installed/active") >> "$M"
(auditctl -l 2>/dev/null | grep -c . | sed 's/^/audit rules loaded: /') >> "$M"

echo "[4/4] Parsing results..."
python3 "$HERE/parse_results.py" "$OUT" || echo "Parser failed; raw evidence is still saved." >&2

cp "$TOOLS/toolchain.txt" "$OUT/" 2>/dev/null
tar -czf "$HERE/../results/evidence-$LABEL-$STAMP.tar.gz" -C "$HERE/../results" "$(basename "$OUT")"
# Hand ownership back to the admin user so results can be copied off the VM with scp
[[ -n "${SUDO_USER:-}" ]] && chown -R "$SUDO_USER": "$HERE/../results"
chmod -R u+rwX,go+rX "$HERE/../results"
echo
echo "Done. Evidence folder: $OUT"
echo "Evidence bundle:        results/evidence-$LABEL-$STAMP.tar.gz"
