# GitHub Actions 构建 Lago 镜像

工作流 `.github/workflows/build-acr-images.yml` 从当前 Lago 根仓库检出已固定版本的
`api` 和 `front` 子模块，构建 `linux/amd64` 镜像并推送到阿里云 ACR。

## ACR 准备

在目标 ACR 命名空间中创建两个私有镜像仓库：

- `lago-api`
- `lago-front`

## GitHub 仓库配置

进入 GitHub 仓库的 `Settings -> Secrets and variables -> Actions`。

创建 Variables：

- `ACR_REGISTRY`：ACR 登录域名，不包含 `https://`，例如
  `crpi-example.cn-hangzhou.personal.cr.aliyuncs.com`
- `ACR_NAMESPACE`：ACR 命名空间，例如 `lago-linx-test`

创建 Secrets：

- `ACR_USERNAME`：拥有目标仓库推送权限的 ACR 用户名
- `ACR_PASSWORD`：对应的 ACR 登录密码或访问凭证

不要把 ACR 用户名或密码提交到仓库文件中。

## 触发与产物

以下情况会触发构建：

- 推送 `feat/apple-iap-paid-voice-clone` 分支，且根工作流或子模块指针发生变化
- 在 GitHub Actions 页面手动运行 `Build Lago Images to ACR`

两个镜像使用相同的 Lago 根仓库提交 SHA：

```text
<ACR_REGISTRY>/<ACR_NAMESPACE>/lago-api:<GITHUB_SHA>
<ACR_REGISTRY>/<ACR_NAMESPACE>/lago-front:<GITHUB_SHA>
```

API、Worker 和 Clock 使用 `lago-api` 镜像；管理界面使用 `lago-front` 镜像。
1Panel 编排中的 `IMAGE_TAG` 应设置为本次工作流显示的完整 `GITHUB_SHA`。

## 私有子模块

当前 Fork 的 `api` 和 `front` 仓库必须允许 GitHub Actions 拉取。若以后改为私有仓库，
需要为根仓库配置一个可以读取两个子模块的 GitHub Token，并在 checkout 步骤中使用该
Token。
