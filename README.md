# DCS GenPilot → 在线 JupyterLab

把这个仓库地址交给 **DCS GenPilot**，让它自动安装 skill、启动独立的 JupyterLab，并把可复制的访问地址发给你。进入浏览器后，你可以自己操作终端、文件和已有的 Python、R 或其他内核，也可以继续安装自己的内核。

## 直接发给 GenPilot

在 GenPilot 对话框粘贴下面这段话即可。首次使用会安装；以后说“打开 JupyterLab”就会自动调用已安装的 skill。

```text
请安装并使用这个 DCS GenPilot skill：https://github.com/yf8578/jupyterlab-online-access
请在云任务 Pod 中检查已有版本；需要时克隆仓库并运行 references/install.sh，加载 general/jupyterlab-online-access，然后启动独立的 JupyterLab。确认网关和 /lab 都可访问后，把本次完整网址放在代码块中给我，我会复制到已登录 DCS 的浏览器地址栏打开。以后我说“打开 JupyterLab”时直接调用这个 skill。
```

GenPilot 首次运行云端脚本时可能弹出平台确认卡片；在卡片中按自己的意愿操作。你无需手工 `git clone`、配置网关路径或猜端口。若当前对话不能即时发现新装的 skill，GenPilot 可从安装路径读取 `SKILL.md` 完成本次启动，新对话会正常索引。

## 它自动做什么

1. 检查个人 skill 列表；从本仓库安装或更新到 `/home/<用户>/skills/main/general/jupyterlab-online-access`。旧版会备份到 `/work/<用户>/jupyterlab-skill-backups/`。
2. 检查云端 JupyterLab。默认使用 `/home/<用户>/software/miniforge/envs/R443`；缺失时按 DCS 软件安装流程补齐。R 内核是可选项，缺失不会阻止其他内核启动；指向可执行 R 的同名配置也不会被覆盖。
3. 通过 `cloud_terminal_run_script_file` 取得平台分配的 Web 槽位、网关 URL 和端口，启动 JupyterLab。
4. 检查本地 `/static/genpilot_marker.txt` 与 `/lab`，再用 DCS 的 `resolve_notebook_app_access` 核验网关，最后输出本次可复制的网址。

**GenPilot 内嵌 notebook 与这里启动的 JupyterLab 是两套界面。** 内嵌编辑器的内核菜单依赖容器 `PATH` 中的 `Rscript`；这个 skill 不修改它。独立 JupyterLab 读取 Jupyter kernelspec，因此可以选择或安装自己的内核。

## 再次使用或更新

- 直接说“打开 JupyterLab”或“给我 JupyterLab 浏览器地址”，GenPilot 会自动调用已安装的 skill。
- 要更新时说“从 https://github.com/yf8578/jupyterlab-online-access 更新这个 skill，然后打开 JupyterLab”。安装脚本会备份旧版。
- 容器停机、网关会话变化或链接失效后，再说“重新启动 JupyterLab”，它会生成当前任务的新地址。

## 可选配置

| 变量 | 用途 | 默认值 |
|---|---|---|
| `JUPYTER_ENV_PREFIX` | 含 `jupyter-lab` 的 conda 环境 | `/home/<用户>/software/miniforge/envs/R443` |
| `R_KERNEL_ENV_PREFIX` | 需要注册的 R 环境 | 与 `JUPYTER_ENV_PREFIX` 相同 |
| `CONFIGURE_R_KERNEL` | `auto` 尝试注册；`required` 必须成功；`off` 跳过 | `auto` |
| `R_KERNEL_NAME` | R kernelspec 名称 | `ir443` |
| `R_KERNEL_REPLACE` | 设为 `1` 才覆盖已有有效的同名 R 内核 | `0` |
| `NOTEBOOK_ROOT_DIR` | JupyterLab 文件浏览器根目录 | `/work/<用户>` |

`start.sh` 关闭 Jupyter token，仅限已鉴权且不能直连服务端口的 DCS notebook 网关。仓库不保存 API 密钥。R 图标出现只证明 kernelspec 存在；真正验证 R 还要在 notebook 中运行 `R.version.string`。

## 仓库文件

- `SKILL.md`：GenPilot 自动触发、安装、启动和交付链接的指令。
- `references/install.sh`：安装或更新个人 skill，并备份旧版。
- `references/start.sh`：通过 DCS 网关启动 JupyterLab。
- `references/setup_r_kernel.sh`：可选地注册 R 内核，不影响其他内核。

若 AI 无法直接读取 GitHub，可下载 [Releases](https://github.com/yf8578/jupyterlab-online-access/releases) 中的 ZIP，使用 GenPilot 技能商店的“上传技能”导入；这是备用方式。
