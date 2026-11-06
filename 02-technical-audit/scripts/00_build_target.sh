#!/usr/bin/env bash
# =============================================================================
# 00_build_target.sh
# Recreates the "as-found" state of cedar-intake01 (Cedar Elm Referral Intake
# Portal) on a fresh Ubuntu 24.04 LTS Server VM.
#
#   - Installs the application stack: nginx (TLS reverse proxy), Gunicorn +
#     Flask app, PostgreSQL 16.
#   - Loads SYNTHETIC referral data only. No real patient data is used.
#   - Seeds five documented "as-found" conditions from the client narrative
#     (see SEEDED CONDITIONS below and 02-technical-audit/README.md).
#
# Run once, as root, on a disposable lab VM (NAT networking recommended):
#   sudo bash 00_build_target.sh
# =============================================================================
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Run as root (sudo)." >&2; exit 1; fi
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release; then
  echo "This script targets Ubuntu 24.04 LTS." >&2; exit 1
fi

APP_DIR=/opt/intake-portal
DATA_DIR=/srv/intake
UPLOADS=$DATA_DIR/uploads
LOG=/var/log/cedar-build.log
exec > >(tee -a "$LOG") 2>&1
echo "== cedar-intake01 build started $(date -Is) =="

# --- Identity ---------------------------------------------------------------
hostnamectl set-hostname cedar-intake01
grep -q cedar-intake01 /etc/hosts || echo "127.0.1.1 cedar-intake01" >> /etc/hosts

# --- Application stack ------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q nginx postgresql python3-flask python3-psycopg2 gunicorn openssl

id intake &>/dev/null || useradd --system --home-dir "$APP_DIR" --shell /usr/sbin/nologin intake
mkdir -p "$APP_DIR" "$UPLOADS"

cat > "$APP_DIR/app.py" <<'PY'
"""Cedar Elm Referral Intake Portal (lab replica). Synthetic data only."""
import os, uuid, datetime
import psycopg2
from flask import Flask, request, render_template_string

UPLOADS = "/srv/intake/uploads"
app = Flask(__name__)

FORM = """<!doctype html><title>Cedar Elm Referral Intake</title>
<h2>Cedar Elm Physical Therapy - Referral Upload</h2>
<p>For referring providers. Lab replica: do not upload real patient data.</p>
<form method=post enctype=multipart/form-data>
 Referring practice: <input name=practice><br>
 Patient last name: <input name=last><br>
 Referral packet: <input type=file name=packet><br>
 <input type=submit value=Upload></form>{{ msg }}"""

def db():
    return psycopg2.connect(dbname="intake", user="intake", host="/var/run/postgresql")

@app.route("/", methods=["GET", "POST"])
def upload():
    msg = ""
    if request.method == "POST" and "packet" in request.files:
        f = request.files["packet"]
        name = f"{uuid.uuid4()}.bin"
        f.save(os.path.join(UPLOADS, name))
        with db() as c, c.cursor() as cur:
            cur.execute("INSERT INTO referrals (practice, patient_last, file_name, received_at)"
                        " VALUES (%s,%s,%s,%s)",
                        (request.form.get("practice"), request.form.get("last"), name,
                         datetime.datetime.now()))
        msg = "Received."
    return render_template_string(FORM, msg=msg)
PY

cat > /etc/systemd/system/intake-portal.service <<'UNIT'
[Unit]
Description=Cedar Elm Referral Intake Portal (gunicorn)
After=network.target postgresql.service

[Service]
User=intake
Group=www-data
WorkingDirectory=/opt/intake-portal
ExecStart=/usr/bin/gunicorn --workers 2 --bind 127.0.0.1:8000 app:app
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

# --- Database ---------------------------------------------------------------
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='intake'" | grep -q 1 \
  || sudo -u postgres createuser intake
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='intake'" | grep -q 1 \
  || sudo -u postgres createdb -O intake intake
sudo -u intake psql -d intake -q <<'SQL'
CREATE TABLE IF NOT EXISTS referrals (
  id SERIAL PRIMARY KEY,
  practice TEXT, patient_last TEXT, patient_first TEXT, dob DATE,
  payer TEXT, member_id TEXT, icd10 TEXT, file_name TEXT,
  received_at TIMESTAMP);
SQL

# --- Synthetic data (clearly labeled, not real PHI) -------------------------
python3 - <<'PY'
import random, uuid, datetime, subprocess
random.seed(2026)
first = ["Ava","Liam","Sofia","Noah","Mia","Elijah","Camila","Mateo","Harper","Lucas","Aaliyah","Ethan"]
last  = ["Ramirez","Nguyen","Patel","Johnson","Okoro","Williams","Garcia","Kim","Brooks","Hernandez"]
payers = ["BCBSTX","Aetna","UHC","Medicare","Texas Mutual (WC)","Cigna"]
icd = ["M25.561","M75.101","S83.511A","M54.50","Z96.651","M17.11"]
practices = ["Trinity Ortho Assoc (SYNTH)","Arlington Family Med (SYNTH)","Mid-Cities Sports Med (SYNTH)"]
rows = []
for i in range(60):
    fn = f"{uuid.uuid4()}.txt"
    f, l = random.choice(first), random.choice(last)
    dob = datetime.date(1950,1,1) + datetime.timedelta(days=random.randint(0, 25000))
    payer, mid, dx = random.choice(payers), f"SYN{random.randint(10**8,10**9-1)}", random.choice(icd)
    pr = random.choice(practices)
    open(f"/srv/intake/uploads/{fn}","w").write(
        f"*** SYNTHETIC TEST DATA - NOT A REAL PATIENT ***\nReferral from {pr}\n"
        f"Patient: {l}, {f}  DOB: {dob}\nPayer: {payer}  Member ID: {mid}\nDx: {dx}\n"
        "Order: PT eval and treat, 2-3x/week x 6 weeks\n")
    ts = datetime.datetime(2024,1,2) + datetime.timedelta(hours=random.randint(0, 24*660))
    rows.append(f"('{pr}','{l}','{f}','{dob}','{payer}','{mid}','{dx}','{fn}','{ts}')")
sql = "INSERT INTO referrals (practice,patient_last,patient_first,dob,payer,member_id,icd10,file_name,received_at) VALUES " + ",".join(rows) + ";"
subprocess.run(["sudo","-u","intake","psql","-d","intake","-q","-c",sql], check=True)
print("Loaded 60 synthetic referral packets.")
PY

# --- nginx TLS reverse proxy (self-signed for the lab) ----------------------
mkdir -p /etc/nginx/tls
[[ -f /etc/nginx/tls/intake.crt ]] || openssl req -x509 -newkey rsa:2048 -nodes -days 825 \
  -subj "/CN=intake.cedarelmpt.example" \
  -keyout /etc/nginx/tls/intake.key -out /etc/nginx/tls/intake.crt
cat > /etc/nginx/sites-available/intake <<'NGX'
server {
    listen 443 ssl;
    server_name intake.cedarelmpt.example;
    ssl_certificate     /etc/nginx/tls/intake.crt;
    ssl_certificate_key /etc/nginx/tls/intake.key;
    client_max_body_size 25m;
    location / { proxy_pass http://127.0.0.1:8000; proxy_set_header Host $host; }
}
NGX
ln -sf /etc/nginx/sites-available/intake /etc/nginx/sites-enabled/intake

# =============================================================================
# SEEDED CONDITIONS (as described in 01-company-profile/company-profile.md)
# Each is labeled AF-# so the report can trace it.
# =============================================================================

# AF-1: Former contractor's account never removed; still in the sudo group.
#       Random password: the issue is account lifecycle, not password guessing.
if ! id jmorales &>/dev/null; then
  useradd -m -s /bin/bash -c "J. Morales (contract developer, 2023-2024)" jmorales
  echo "jmorales:$(openssl rand -base64 18)" | chpasswd
  usermod -aG sudo jmorales
fi

# AF-2: SSH password authentication explicitly enabled by the contractor.
cat > /etc/ssh/sshd_config.d/50-cedar.conf <<'SSH'
# Added 2023 by contractor so referring-office IT could help troubleshoot
PasswordAuthentication yes
SSH

# AF-3: Upload directory and files are world-readable and world-writable.
chown -R intake:www-data "$DATA_DIR"
chmod 0777 "$UPLOADS"
find "$UPLOADS" -type f -exec chmod 0666 {} +

# AF-4: PostgreSQL listens on all interfaces and accepts the VPN range.
PGCONF=$(ls /etc/postgresql/*/main/postgresql.conf | head -1)
PGHBA=$(dirname "$PGCONF")/pg_hba.conf
sed -i "s/^#\?listen_addresses.*/listen_addresses = '*'/" "$PGCONF"
grep -q "10.0.0.0/8" "$PGHBA" || echo "host    intake    intake    10.0.0.0/8    scram-sha-256" >> "$PGHBA"

# AF-5: Automatic security updates disabled ("updates broke the app once").
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'APT'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "0";
APT
# =============================================================================

systemctl daemon-reload
systemctl enable --now intake-portal
systemctl restart postgresql nginx ssh || systemctl restart postgresql nginx sshd
sleep 2
if curl -sk -o /dev/null -w "%{http_code}" https://127.0.0.1/ | grep -q 200; then
  echo "Portal responding on https://127.0.0.1/ (self-signed cert)."
else
  echo "WARNING: portal did not return HTTP 200. Check: systemctl status intake-portal" >&2
fi
echo "== Build complete $(date -Is). Take a VM snapshot named 'as-found' now. =="
