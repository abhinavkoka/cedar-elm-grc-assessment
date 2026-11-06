#!/usr/bin/env bash
# =============================================================================
# 01_install_tools.sh
# Installs the free, open-source assessment toolchain and records exact
# versions and checksums as audit evidence.
#
#   OpenSCAP scanner      (Ubuntu archive)
#   Lynis                 (Ubuntu archive)
#   ComplianceAsCode SCAP content (scap-security-guide), CIS Ubuntu 24.04 profiles
#
#   sudo bash 01_install_tools.sh
# =============================================================================
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }

SSG_VERSION="${SSG_VERSION:-0.1.82}"
TOOLS=/opt/cedar-audit
DS="$TOOLS/ssg-ubuntu2404-ds.xml"
mkdir -p "$TOOLS"

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q openscap-scanner openscap-utils lynis unzip git curl python3-lxml

if [[ ! -f "$DS" ]]; then
  echo "Fetching ComplianceAsCode content v$SSG_VERSION ..."
  ZIP="/tmp/scap-security-guide-$SSG_VERSION.zip"
  URL="https://github.com/ComplianceAsCode/content/releases/download/v$SSG_VERSION/scap-security-guide-$SSG_VERSION.zip"
  if curl -fL --retry 3 -o "$ZIP" "$URL"; then
    unzip -o -q "$ZIP" "*/ssg-ubuntu2404-ds.xml" -d /tmp/ssg && \
      cp /tmp/ssg/*/ssg-ubuntu2404-ds.xml "$DS" || true
  fi
fi

if [[ ! -f "$DS" ]]; then
  echo "Release zip unavailable or missing Ubuntu 24.04 content; building from source (5-10 min)..."
  apt-get install -y -q cmake ninja-build python3-jinja2 python3-yaml python3-setuptools \
    xsltproc libxml2-utils expat
  rm -rf /tmp/cac && git clone -q --depth 1 --branch "v$SSG_VERSION" \
    https://github.com/ComplianceAsCode/content /tmp/cac
  (cd /tmp/cac && ./build_product ubuntu2404 --datastream-only)
  cp /tmp/cac/build/ssg-ubuntu2404-ds.xml "$DS"
fi

oscap info --profiles "$DS" | grep -q cis_level1_server \
  || { echo "CIS Level 1 Server profile not found in $DS" >&2; exit 1; }

{
  echo "# Toolchain evidence - recorded $(date -Is) on $(hostname)"
  echo "oscap:        $(oscap --version | head -1)"
  echo "lynis:        $(lynis --version)"
  echo "SSG content:  ComplianceAsCode v$SSG_VERSION"
  echo "SSG sha256:   $(sha256sum "$DS" | cut -d' ' -f1)"
  echo "Profile:      xccdf_org.ssgproject.content_profile_cis_level1_server"
  echo "Benchmark:    $(oscap info --profiles "$DS" | grep cis_level1_server | cut -d: -f2-)"
  echo "OS:           $(. /etc/os-release; echo "$PRETTY_NAME"), kernel $(uname -r)"
} | tee "$TOOLS/toolchain.txt"
echo "Tools ready in $TOOLS"
