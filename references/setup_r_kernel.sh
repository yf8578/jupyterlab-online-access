#!/usr/bin/env bash
set -euo pipefail
JUPYTER_ENV_PREFIX="${JUPYTER_ENV_PREFIX:-/home/zhangyifan1/software/miniforge/envs/R443}"
R_ENV_PREFIX="${R_KERNEL_ENV_PREFIX:-${JUPYTER_ENV_PREFIX}}"
for name in R Rscript; do
  if [[ ! -x "${R_ENV_PREFIX}/bin/${name}" ]]; then
    echo "Missing ${R_ENV_PREFIX}/bin/${name}; set R_KERNEL_ENV_PREFIX to an environment with R and IRkernel." >&2
    exit 1
  fi
done
for name in jupyter python; do
  if [[ ! -x "${JUPYTER_ENV_PREFIX}/bin/${name}" ]]; then
    echo "Missing ${JUPYTER_ENV_PREFIX}/bin/${name}; set JUPYTER_ENV_PREFIX to an environment with JupyterLab." >&2
    exit 1
  fi
done
export PATH="${R_ENV_PREFIX}/bin:${JUPYTER_ENV_PREFIX}/bin:${PATH}"
export R_HOME="$("${R_ENV_PREFIX}/bin/R" RHOME)"
if ! "${R_ENV_PREFIX}/bin/Rscript" --vanilla -e 'quit(status=if (requireNamespace("IRkernel", quietly=TRUE)) 0 else 1)' >/dev/null 2>&1; then
  echo "IRkernel is missing in ${R_ENV_PREFIX}. Install r-irkernel into this environment, then rerun." >&2
  exit 1
fi
KERNEL_NAME="${R_KERNEL_NAME:-ir443}"
if [[ ! "${KERNEL_NAME}" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Invalid R_KERNEL_NAME: ${KERNEL_NAME}" >&2
  exit 1
fi
DATA_DIR="$("${JUPYTER_ENV_PREFIX}/bin/jupyter" --data-dir)"
KERNEL_DIR="${DATA_DIR}/kernels/${KERNEL_NAME}"
mkdir -p "${KERNEL_DIR}"
"${JUPYTER_ENV_PREFIX}/bin/python" - "${KERNEL_DIR}/kernel.json" "${R_ENV_PREFIX}/bin/R" "${R_HOME}" "${KERNEL_NAME}" <<'PY'
import json
import pathlib
import sys
target, r_bin, r_home, name = sys.argv[1:]
spec = {
    "argv": [r_bin, "--slave", "-e", "IRkernel::main()", "--args", "{connection_file}"],
    "display_name": f"R ({name})",
    "language": "R",
    "env": {"R_HOME": r_home},
}
pathlib.Path(target).write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")
PY
"${JUPYTER_ENV_PREFIX}/bin/jupyter" kernelspec list --json | "${JUPYTER_ENV_PREFIX}/bin/python" -c '
import json, sys
name = sys.argv[1]
specs = json.load(sys.stdin)["kernelspecs"]
if name not in specs or specs[name]["spec"]["language"].lower() != "r":
    raise SystemExit(f"R kernel {name!r} is not visible to Jupyter")
print(f"R kernel registered: {name}")
' "${KERNEL_NAME}"
