---
name: jupyterlab-online-access
description: 在 Genpilot 云平台启动 JupyterLab，确保 R 内核被注册，并给用户可复制到浏览器的访问网址。
version: 1.1.0
---

# 在线 JupyterLab

当用户在 GenPilot 中要求启动在线 JupyterLab、使用 R notebook 或获取浏览器访问网址时使用本 skill。本 skill 启动独立的 JupyterLab；GenPilot 内嵌 notebook 的内核选择器按 `PATH` 探测 `Rscript`，不会因为注册 Jupyter kernelspec 就出现 R。

## 环境

- 在云端执行，不在用户本机执行。平台的脚本运行器须注入 `NOTEBOOK_GATEWAY_URL` 和 `STREAMLIT_PORT`。
- 默认 conda 环境是 `/home/zhangyifan1/software/miniforge/envs/R443`；不同环境设置 `JUPYTER_ENV_PREFIX`。
- 环境必须已有 JupyterLab、R 和 IRkernel。若缺 IRkernel，先在该环境安装 `r-irkernel`，再启动。
- 网关须对访问者进行身份验证；`start.sh` 关闭 Jupyter 的 token，因此不可将端口直接暴露到公网。

## 启动

1. 将本仓库放在云端可执行目录，例如 `git clone https://github.com/yf8578/jupyterlab-online-access.git /work/zhangyifan1/jupyterlab-online-access`。
2. 通过 Genpilot 的云端脚本运行器执行 `references/start.sh`，让运行器提供网关 URL 和端口。不要在普通 shell 中猜测任务 ID 或槽位。
3. 脚本会验证 R 和 IRkernel，生成指向当前环境中 R 可执行文件的 `ir443` kernelspec，确认 Jupyter 能看到它，然后启动 JupyterLab。
4. 从运行器返回值读取 `notebook_gateway_url` 和 `selected_app_port`。浏览器地址是 `${notebook_gateway_url%/}/lab`。
5. 就绪验证：用选定端口和网关 URL 的 path，分别检查 `/static/genpilot_marker.txt` 与 `/lab`，两者均应返回 HTTP 200。允许扩展启动耗时，轮询最多约 2 分钟。
6. 给用户完整地址，以代码块展示，便于复制到自己的浏览器。告知用户要在已登录 DCS 的浏览器中打开。

## 排错

- `IRkernel is missing`：在 `JUPYTER_ENV_PREFIX` 指向的环境安装 `r-irkernel`。不可只在另一个 R 环境安装。
- `R kernel ... is not visible`：检查 `jupyter --data-dir`、`JUPYTER_DATA_DIR` 和运行服务的 Unix 用户是否一致。
- 启动后图标存在但 R cell 不能运行：检查 `kernelspec list --json` 的 `argv[0]` 是否为当前环境的 `bin/R`，并在该 R 中执行 `IRkernel::main()` 的前置依赖检查。
- 本地 200 但浏览器打不开：检查网关权限、DCS 登录状态和用户端网络；不能仅据本地探针断定公网可达。

完整部署与手工验证步骤见 [README.md](README.md)。
