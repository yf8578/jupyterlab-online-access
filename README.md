# Genpilot JupyterLab：R 内核与浏览器访问

这个仓库提供 **GenPilot 中调用**的 JupyterLab 启动 skill。它先把 **当前 conda 环境中的 R** 注册为 `ir443` 内核，再通过平台提供的 notebook 网关启动**独立的 JupyterLab**，并输出可复制的 `/lab` 地址。

GenPilot 自带的内嵌 notebook 只显示 Python 时，这个 skill 提供另一条使用 R notebook 的路径：在浏览器打开独立 JupyterLab。它不会改变 GenPilot 内嵌 notebook 的内核下拉框；该下拉框依赖容器 `PATH` 中可探测的 `Rscript`，不读取 Jupyter kernelspec。

截图里出现 R 图标只说明 Jupyter 找到了一个 kernelspec，不能证明其 `argv` 仍指向有效的 R。`setup_r_kernel.sh` 每次启动前更新 kernelspec，避免旧配置指向别的环境。

## 云端准备

```bash
git clone https://github.com/yf8578/jupyterlab-online-access.git /work/zhangyifan1/jupyterlab-online-access
```

默认环境：`/home/zhangyifan1/software/miniforge/envs/R443`。它需包含 `R`、`Rscript`、`IRkernel`、`python`、`jupyter` 和 `jupyter-lab`。如 IRkernel 尚未安装，可在云端运行：

```bash
conda install -p /home/zhangyifan1/software/miniforge/envs/R443 -c conda-forge r-irkernel
```

实际安装是否可行取决于云平台的 conda 权限和网络。若环境位于别处，设置 `JUPYTER_ENV_PREFIX`。可用 `NOTEBOOK_ROOT_DIR` 指定文件浏览器根目录，默认 `/work/zhangyifan1`。

## 在 Genpilot 中启动

用**云端脚本运行器**运行：

```text
/work/zhangyifan1/jupyterlab-online-access/references/start.sh
```

运行器应注入 `NOTEBOOK_GATEWAY_URL` 和 `STREAMLIT_PORT`，并返回 `notebook_gateway_url` 与 `selected_app_port`。脚本会打印：

```text
JupyterLab URL: https://<网关主机>/notebook/st-gw/<任务>/<槽位>/<用户>/lab
```

复制完整 URL 到已登录 DCS 的浏览器地址栏。此地址由**本次云端任务的网关 URL**产生，仓库中的示例不能直接访问。服务须保持运行，地址才可用。

## 验证 R 内核

在同一云端环境执行：

```bash
export JUPYTER_ENV_PREFIX=/home/zhangyifan1/software/miniforge/envs/R443
bash /work/zhangyifan1/jupyterlab-online-access/references/setup_r_kernel.sh
"$JUPYTER_ENV_PREFIX/bin/jupyter" kernelspec list --json
```

确认 `ir443` 的 `language` 是 `R`，且 `argv[0]` 指向该环境的 `bin/R`。浏览器中新建 **R (ir443)** notebook，运行 `R.version.string` 检查实际版本。`R` 和 `R 4.4.3` 等已有图标可能来自其他 kernelspec，不应只凭图标判断配置成功。

## 网关与安全

`start.sh` 关闭 Jupyter token，依赖 DCS 网关验证用户身份。只在已经鉴权且限制直连云端端口的网关下使用。启动脚本不携带 API 密钥，也不预设 AI 插件的密钥。

本仓库无法替代云平台对 R 软件包安装、端口分配或网关权限的管理。如果本地 `/lab` 健康检查为 200 而浏览器仍不可达，应检查用户端网络、登录状态和网关规则。

## 文件

- `SKILL.md`：供 Genpilot 使用的操作说明。
- `references/setup_r_kernel.sh`：注册并验证当前环境的 R 内核。
- `references/start.sh`：启动 JupyterLab 并输出浏览器地址。
