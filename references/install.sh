#!/usr/bin/env bash
# Install this checkout as a personal DCS GenPilot skill.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="$(id -un)"
SKILL_PARENT="${GENPILOT_SKILL_PARENT:-/home/${USER_NAME}/skills/main/general}"
TARGET="${SKILL_PARENT}/jupyterlab-online-access"
BACKUP_PARENT="${GENPILOT_SKILL_BACKUP_PARENT:-/work/${USER_NAME}/jupyterlab-skill-backups}"

for file in SKILL.md README.md LICENSE references/start.sh references/setup_r_kernel.sh; do
  if [[ ! -f "${SOURCE_DIR}/${file}" ]]; then
    echo "Incomplete checkout: ${SOURCE_DIR}/${file} is missing." >&2
    exit 1
  fi
done

mkdir -p "${SKILL_PARENT}"
STAGING="$(mktemp -d "${SKILL_PARENT}/.jupyterlab-online-access.XXXXXX")"
trap 'rm -rf "${STAGING}"' EXIT
install -m 0644 "${SOURCE_DIR}/SKILL.md" "${STAGING}/SKILL.md"
install -m 0644 "${SOURCE_DIR}/README.md" "${STAGING}/README.md"
install -m 0644 "${SOURCE_DIR}/LICENSE" "${STAGING}/LICENSE"
mkdir -p "${STAGING}/references"
install -m 0755 "${SOURCE_DIR}/references/start.sh" "${STAGING}/references/start.sh"
install -m 0755 "${SOURCE_DIR}/references/setup_r_kernel.sh" "${STAGING}/references/setup_r_kernel.sh"
install -m 0755 "${SOURCE_DIR}/references/install.sh" "${STAGING}/references/install.sh"

if [[ -e "${TARGET}" ]]; then
  mkdir -p "${BACKUP_PARENT}"
  BACKUP="${BACKUP_PARENT}/jupyterlab-online-access.$(date +%Y%m%dT%H%M%S).$$"
  mv "${TARGET}" "${BACKUP}"
  echo "Previous skill saved at ${BACKUP}"
fi
if ! mv "${STAGING}" "${TARGET}"; then
  if [[ -n "${BACKUP:-}" ]]; then mv "${BACKUP}" "${TARGET}"; fi
  echo "Installation failed; restored previous skill if present." >&2
  exit 1
fi
trap - EXIT
echo "Installed: ${TARGET}/SKILL.md"
echo "Start script: ${TARGET}/references/start.sh"
