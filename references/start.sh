#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PREFIX="${JUPYTER_ENV_PREFIX:-/home/zhangyifan1/software/miniforge/envs/R443}"
JUPYTER_LAB="${ENV_PREFIX}/bin/jupyter-lab"
if [[ ! -x "${JUPYTER_LAB}" ]]; then
  echo "Missing JupyterLab: ${JUPYTER_LAB}; set JUPYTER_ENV_PREFIX." >&2
  exit 1
fi
: "${NOTEBOOK_GATEWAY_URL:?The DCS script runner must provide NOTEBOOK_GATEWAY_URL}"
PORT="${STREAMLIT_PORT:-8888}"
if [[ ! "${PORT}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "Invalid STREAMLIT_PORT: ${PORT}" >&2
  exit 1
fi
export PATH="${ENV_PREFIX}/bin:${PATH}"
"${SCRIPT_DIR}/setup_r_kernel.sh"
BASE_PATH="$("${ENV_PREFIX}/bin/python" - "${NOTEBOOK_GATEWAY_URL}" <<'PY'
import sys
from urllib.parse import urlsplit
url = urlsplit(sys.argv[1])
if url.scheme != "https" or not url.netloc or not url.path.startswith("/notebook/"):
    raise SystemExit("Expected an HTTPS notebook gateway URL")
print(url.path.rstrip("/") + "/")
PY
)"
NOTEBOOK_ROOT_DIR="${NOTEBOOK_ROOT_DIR:-/work/zhangyifan1}"
if [[ ! -d "${NOTEBOOK_ROOT_DIR}" ]]; then
  echo "Notebook root directory does not exist: ${NOTEBOOK_ROOT_DIR}" >&2
  exit 1
fi
STATIC_DIR="${SCRIPT_DIR}/static"
mkdir -p "${STATIC_DIR}"
cat > "${STATIC_DIR}/genpilot_marker.txt" <<EOF
$(basename "$(dirname "${SCRIPT_DIR}")")
app_dir=$(dirname "${SCRIPT_DIR}")
app_type=static
started_at=$(date +%s)
pid=$$
EOF
echo "JupyterLab URL: ${NOTEBOOK_GATEWAY_URL%/}/lab" >&2
exec "${JUPYTER_LAB}" \
  --ip=0.0.0.0 --port="${PORT}" --no-browser \
  --ServerApp.base_url="${BASE_PATH}" \
  --ServerApp.root_dir="${NOTEBOOK_ROOT_DIR}" \
  --IdentityProvider.token='' \
  --ServerApp.extra_static_paths="${STATIC_DIR}" \
  --ServerApp.trust_xheaders=True
