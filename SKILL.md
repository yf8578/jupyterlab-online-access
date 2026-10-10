---
name: jupyterlab-online-access
description: DCS GenPilot 用户说“打开/启动 JupyterLab、在线 notebook、给我可复制的浏览器地址、想自己配置 R/Python/其他内核”时自动调用。自动准备云端 JupyterLab、启动网关应用并验证链接。
version: 1.3.0
---

# 在 DCS GenPilot 中启动独立 JupyterLab

用户要的是能在自己的浏览器里操作的完整 JupyterLab，包括终端、文件浏览器和 Jupyter kernelspec 内核。GenPilot 内嵌 `.ipynb` 编辑器的内核选择机制不同；不要试图通过注册 kernelspec 修改它的下拉框。若用户仅要求读写现有 `.ipynb` 的 cell，不触发本 skill。

## 自动安装与更新

若用户给出本仓库 `https://github.com/yf8578/jupyterlab-online-access` 并要求安装、更新或使用：无需让用户手工下载 ZIP、打开终端或逐条执行命令。先用 `skills_list` 检查 `general/jupyterlab-online-access`。缺失或版本低于本仓库时，在**云任务 Pod** 使用 `terminal_exec`：

1. `id -un` 取得真实用户名。个人 skill 目录是 `/home/<user>/skills/main/general/jupyterlab-online-access`。
2. 将 GitHub 仓库克隆到 `/work/<user>/jupyterlab-online-access-source`。若该目录已有同一仓库且工作区干净，可 `git -C <dir> pull --ff-only`；若有本地改动，改用新的临时克隆目录，保留原目录。
3. 运行克隆目录中的 `bash references/install.sh`。脚本将旧 skill 备份到 `/work/<user>/jupyterlab-skill-backups/`，再安装 `SKILL.md` 和脚本。不要直接覆盖可能被用户修改的旧版。
4. 调 `skills_list` 确认它已出现，再调 `skill_view` 加载 `general/jupyterlab-online-access`。若技能索引未即时刷新，按安装后的绝对路径读取 `SKILL.md`，在下一轮会话中再用 `skill_view`；不要声称注册成功而不核验。

已安装且用户只是要打开 JupyterLab 时，直接执行以下流程，不要每次重新克隆。用户明确要求更新时才拉取最新仓库。

## 自动启动

1. 用 `terminal_exec` 检查 `/home/<user>/skills/main/general/jupyterlab-online-access/references/start.sh`、`/work/<user>` 与 JupyterLab 可执行文件。默认环境为 `/home/<user>/software/miniforge/envs/R443`。如 JupyterLab 缺失，按平台 `software-install-guidance` 在用户可写的 conda 环境安装并复验；不要因为可选的 R 缺失而阻止其他内核启动。
2. 用 `cloud_terminal_run_script_file(file_path="/home/<user>/skills/main/general/jupyterlab-online-access/references/start.sh")` 启动。此工具会选 Web 槽位并注入 `NOTEBOOK_GATEWAY_URL`、`STREAMLIT_PORT`。它的系统确认卡片由平台处理；不要用 `terminal_exec` 加 `nohup` 启动服务，也不要猜端口或任务 ID。
3. 从工具返回值读取 `data.notebook_gateway_url` 与 `data.selected_app_port`。若启动仍在进行，用 `cloud_terminal_run_script_progress` 或短时健康探针查看进度。不要只凭进程提交成功就交付链接。
4. 用选定端口及网关 URL 的 path 检查 `{base}/static/genpilot_marker.txt` 和 `{base}/lab`，两者均须返回 HTTP 200。扩展加载可能需要 30–120 秒。再调用 `resolve_notebook_app_access(app_name="JupyterLab", app_dir="/home/<user>/skills/main/general/jupyterlab-online-access")` 核验网关；若失败，读启动日志和探针结果，不盲目重复启动或释放别的应用槽位。
5. 验证成功后，给用户可复制的完整 `${notebook_gateway_url%/}/lab`，放入纯文本代码块。告诉用户在已登录 DCS 的浏览器地址栏打开，随后可自行选用或配置内核。此 URL 属于当前云任务；容器停机、网关会话变化后需要重新启动。

## 内核与安全

- `start.sh` 默认尝试准备 `ir443`；若同名配置指向可执行的 R，则保留用户现有配置。若 R 或 IRkernel 不可用，会继续启动 JupyterLab，保留其他已安装内核。指定另一个 R 环境用 `R_KERNEL_ENV_PREFIX`；可设置 `CONFIGURE_R_KERNEL=required|off`。只有用户明确要替换同名内核时才设 `R_KERNEL_REPLACE=1`。
- 若用户要求**必须**能运行 R，启动前用该环境的 `Rscript` 验证 `IRkernel`，必要时按平台软件安装流程补齐；启动后新建 R notebook 运行 `R.version.string`。图标可见不足以证明内核能执行。
- Jupyter token 由脚本关闭，服务仅适用于 DCS 已鉴权的 notebook 网关；不可开放直连端口。脚本不包含 API 密钥。
- 如果本地探针为 200、浏览器仍打不开，排查 DCS 登录、网关权限和用户端网络；不要把网络故障误判为内核问题。

安装与使用说明见同目录 `README.md`。
