#!/usr/bin/env bash
# =============================================================================
# 03_remediate.sh
# Applies the approved remediation plan to cedar-intake01 and writes a change
# record (evidence for change management, NIST SP 800-53 CM-3).
#
# BEFORE RUNNING: take a VM snapshot named "pre-remediation". This is the
# rollback plan. The script asks you to confirm.
#
# Optional settings (environment variables):
#   ADMIN_CIDR=192.168.56.0/24   restrict SSH to an admin subnet (default: any)
#
#   sudo bash 03_remediate.sh
# =============================================================================
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
REM="$HERE/../remediation"
TOOLS=/opt/cedar-audit
DS="$TOOLS/ssg-ubuntu2404-ds.xml"
BASE=cis_level1_server
TAILORED=cedar_intake_remediation
ADMIN_USER="${SUDO_USER:-}"
ADMIN_CIDR="${ADMIN_CIDR:-any}"
STAMP=$(date +%Y%m%d-%H%M%S)
CR="$REM/change-record-$STAMP.md"
export DEBIAN_FRONTEND=noninteractive

step() { printf '\n| %s | %s | ' "$(date +%H:%M:%S)" "$1" >> "$CR"; echo "==> $1"; }
done_() { printf '%s |' "${1:-Completed}" >> "$CR"; }

read -r -p "Have you taken a VM snapshot named 'pre-remediation'? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Take the snapshot first, then re-run."; exit 1; }
[[ -n "$ADMIN_USER" && "$ADMIN_USER" != root ]] || {
  echo "Run with sudo from your admin account (not as root directly) so SSH access can be scoped to you." >&2; exit 1; }

cat > "$CR" <<EOF
# Change Record CR-$STAMP: cedar-intake01 security remediation

| Field | Value |
|---|---|
| System | cedar-intake01 (Referral Intake Portal) |
| Requested by | Security assessment (POA&M items POAM-01 to POAM-06) |
| Approved by | CEO (risk owner), IT Manager (implementer) |
| Executed by | $ADMIN_USER |
| Rollback plan | Revert VM snapshot "pre-remediation" |
| Window | $(date -Is) |

| Time | Step | Outcome |
|---|---|---|
EOF

# --- 1. Patching (AF-5) -----------------------------------------------------
step "Apply all pending updates (full-upgrade)"
apt-get update -q && apt-get -y -q -o Dpkg::Options::=--force-confold full-upgrade \
  && done_ || done_ "FAILED - review apt output"

step "Re-enable unattended security updates"
apt-get install -y -q unattended-upgrades >/dev/null
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'APT'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT
done_

# --- 2. Account lifecycle (AF-1) --------------------------------------------
step "Disable former contractor account jmorales (lock, expire, remove sudo, no shell)"
if id jmorales &>/dev/null; then
  gpasswd -d jmorales sudo >/dev/null 2>&1
  usermod -L -s /usr/sbin/nologin jmorales && chage -E 0 jmorales
  done_ "Disabled; home directory retained for records retention"
else done_ "Account not present"; fi

# --- 3. ePHI data store permissions (AF-3) ----------------------------------
step "Restrict /srv/intake/uploads to service account and web group"
chown -R intake:www-data /srv/intake
chmod 0750 /srv/intake /srv/intake/uploads
find /srv/intake/uploads -type f -exec chmod 0640 {} +
done_

# --- 4. Database exposure (AF-4) --------------------------------------------
step "Bind PostgreSQL to localhost; remove VPN-range access rule"
PGCONF=$(ls /etc/postgresql/*/main/postgresql.conf | head -1)
PGHBA=$(dirname "$PGCONF")/pg_hba.conf
sed -i "s/^listen_addresses.*/listen_addresses = 'localhost'/" "$PGCONF"
sed -i '/10\.0\.0\.0\/8/d' "$PGHBA"
systemctl restart postgresql && done_

# --- 5. CIS automated remediation (tailored) --------------------------------
step "Build tailoring file excluding rules with a recorded baseline decision"
UNSELECT=()
while IFS=, read -r rid _; do
  [[ "$rid" == rule_id || -z "$rid" ]] && continue
  UNSELECT+=(-u "$rid")
done < "$REM/baseline-decisions.csv"
autotailor --title "Cedar Elm intake server remediation (CIS L1 Server, tailored)" \
  -p "$TAILORED" -o "$REM/cedar-tailoring.xml" "${UNSELECT[@]}" "$DS" "$BASE" \
  && done_ "Excluded $(( ${#UNSELECT[@]} / 2 )) rules; see remediation/cedar-tailoring.xml"

step "OpenSCAP --remediate with tailored profile (includes AIDE database init; 5-20 min)"
oscap xccdf eval --remediate \
  --tailoring-file "$REM/cedar-tailoring.xml" \
  --profile "xccdf_org.ssgproject.content_profile_$TAILORED" \
  --results "$REM/remediation-results-$STAMP.xml" \
  "$DS" > "$REM/remediation-stdout-$STAMP.txt" 2>&1
done_ "See remediation-stdout-$STAMP.txt"

# --- 6. SSH (AF-2) and CIS 5.1.4 --------------------------------------------
step "SSH hardening: scope access to $ADMIN_USER; key-only auth if a key is enrolled"
rm -f /etc/ssh/sshd_config.d/50-cedar.conf
KEYS="$(getent passwd "$ADMIN_USER" | cut -d: -f6)/.ssh/authorized_keys"
{
  echo "# Managed by Cedar Elm remediation CR-$STAMP"
  echo "AllowUsers $ADMIN_USER"
  echo "PermitRootLogin no"
  if [[ -s "$KEYS" ]]; then echo "PasswordAuthentication no"; else echo "PasswordAuthentication yes"; fi
} > /etc/ssh/sshd_config.d/10-cedar-hardening.conf
chmod 0600 /etc/ssh/sshd_config.d/10-cedar-hardening.conf
if sshd -t; then
  systemctl reload ssh 2>/dev/null || systemctl reload sshd
  if [[ -s "$KEYS" ]]; then done_ "Key-only authentication enforced"
  else done_ "No SSH key enrolled for $ADMIN_USER: password auth left ON (POAM-05 stays open)"; fi
else
  rm -f /etc/ssh/sshd_config.d/10-cedar-hardening.conf; done_ "FAILED sshd -t; change reverted"
fi

# --- 7. Host firewall (CIS 4.2) ---------------------------------------------
step "UFW: default deny in/out/routed; allow 443 in, SSH from $ADMIN_CIDR, required egress"
apt-get install -y -q ufw >/dev/null
apt-get purge -y -q iptables-persistent >/dev/null 2>&1
ufw --force reset >/dev/null
ufw default deny incoming; ufw default deny outgoing; ufw default deny routed
ufw allow in on lo; ufw allow out on lo
ufw deny in from 127.0.0.0/8; ufw deny in from ::1
ufw allow in 443/tcp comment 'Referral portal'
if [[ "$ADMIN_CIDR" == any ]]; then ufw allow in 22/tcp comment 'Admin SSH'
else ufw allow in from "$ADMIN_CIDR" to any port 22 proto tcp comment 'Admin SSH'; fi
ufw allow out 53 comment 'DNS'; ufw allow out 80/tcp comment 'APT'
ufw allow out 443/tcp comment 'APT/HTTPS'; ufw allow out 123/udp comment 'NTP'
ufw --force enable && systemctl enable ufw >/dev/null 2>&1 && done_

# --- 8. Audit logging for ePHI (HIPAA 164.312(b); beyond CIS Level 1) -------
step "Install auditd and watch ePHI paths, identity files, and privileged config"
apt-get install -y -q auditd audispd-plugins >/dev/null
cat > /etc/audit/rules.d/50-cedar-ephi.rules <<'AUD'
## Cedar Elm: HIPAA audit controls for the Referral Intake Portal
-w /srv/intake/uploads -p rwa -k ephi_access
-w /opt/intake-portal -p wa -k app_change
-w /etc/postgresql -p wa -k db_config
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege
-w /etc/sudoers.d -p wa -k privilege
-w /etc/ssh/sshd_config.d -p wa -k sshd_config
AUD
augenrules --load >/dev/null 2>&1; systemctl enable --now auditd >/dev/null 2>&1
done_ "$(auditctl -l 2>/dev/null | wc -l) audit rules loaded"

# --- 9. Service health check ------------------------------------------------
step "Verify portal still serves HTTPS after hardening"
systemctl restart intake-portal nginx
sleep 2
code=$(curl -sk -o /dev/null -w "%{http_code}" https://127.0.0.1/)
[[ "$code" == 200 ]] && done_ "HTTP 200 - service healthy" || done_ "WARNING: HTTP $code - investigate"

echo >> "$CR"
chown -R "$ADMIN_USER": "$REM"; chmod -R u+rwX,go+rX "$REM"
echo "Remediation finished. Change record: $CR"
echo "Reboot (kernel/boot parameters), then run: sudo bash 02_scan.sh post"
