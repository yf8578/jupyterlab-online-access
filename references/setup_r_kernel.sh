#!/usr/bin/env bash
set -euo pipefail
ENV_PREFIX="${JUPYTER_ENV_PREFIX:-/home/zhangyifan1/software/miniforge/envs/R443}"
for name in R Rscript jupyter python; do
  if [[ ! -x "${ENV_PREFIX}/bin/${name}" ]]; then
    echo "Missing ${ENV_PREFIX}/bin/${name}; set JUPYTER_ENV_PREFIX to an environment with R, IRkernel and JupyterLab." >&2
    exit 1
  fi
done
export PATH="${ENV_PREFIX}/bin:${PATH}"
export R_HOME="$("${ENV_PREFIX}/bin/R" RHOME)"
if ! "${ENV_PREFIX}/bin/Rscript" --vanilla -e 'quit(status=if (requireNamespace("IRkernel", quietly=TRUE)) 0 else 1)' >/dev/null 2>&1; then
  echo "IRkernel is missing in ${ENV_PREFIX}. Install r-irkernel into this environment, then rerun." >&2
  exit 1
fi
KERNEL_NAME="${R_KERNEL_NAME:-ir443}"
if [[ ! "${KERNEL_NAME}" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Invalid R_KERNEL_NAME: ${KERNEL_NAME}" >&2
  exit 1
fi
DATA_DIR="$("${ENV_PREFIX}/bin/jupyter" --data-dir)"
KERNEL_DIR="${DATA_DIR}/kernels/${KERNEL_NAME}"
mkdir -p "${KERNEL_DIR}"
"${ENV_PREFIX}/bin/python" - "${KERNEL_DIR}/kernel.json" "${ENV_PREFIX}/bin/R" "${R_HOME}" "${KERNEL_NAME}" <<'PY'
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
"${ENV_PREFIX}/bin/jupyter" kernelspec list --json | "${ENV_PREFIX}/bin/python" -c '
import json, sys
name = sys.argv[1]
specs = json.load(sys.stdin)["kernelspecs"]
if name not in specs or specs[name]["spec"]["language"].lower() != "r":
    raise SystemExit(f"R kernel {name!r} is not visible to Jupyter")
print(f"R kernel registered: {name}")
' "${KERNEL_NAME}"
