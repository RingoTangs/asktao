# AskTao 1.4 服务端 Docker 使用说明

本文档说明 AskTao 1.4 服务端各子服务的 Docker 使用方式。当前已整理 AAA 镜像；后续可按相同结构补充 CCS、DBA、GS 等服务。

## 目录结构

- `aaa/`：AAA 服务配置和 `pack_data` 资源。
- `build-aaa-image.sh`：构建 AAA Docker 镜像。
- `package-aaa.sh`：打包 AAA 构建文件，便于上传服务器。
- `magic_Linux32`、`runaaa`：AAA 服务运行所需程序和启动脚本。

## 通用约定

- 构建主机预期为 CentOS 7.9，并且当前用户需要能访问 Docker daemon。
- `.ini` 配置文件使用 GBK 编码，编辑时不要转换编码。
- 容器内工作目录为 `/app`。
- 挂载到 `/app` 的宿主机目录为空时，容器会从镜像内置文件初始化；目录非空时不会覆盖已有内容。

## AAA 镜像

- 镜像名：`ringotangs/at-1.4-aaa:0.1`
- 容器名：`at-1.4-aaa`
- 暴露端口：`8101`、`9101`
- 数据库参数：`DB_HOST`、`DB_USER`、`DB_PASSWORD`

`aaa/aaa.ini` 中的 `Host`、`User`、`Password` 使用占位符。容器启动时会用环境变量替换这些值。如果占位符仍存在但没有传对应环境变量，容器会启动失败并提示缺少变量。

### 打包上传

在本地执行：

```sh
cd 1.4_server
./package-aaa.sh
```

上传生成的 `asktao-1.4-aaa.zip` 到 CentOS 7.9 服务器后执行：

```sh
unzip asktao-1.4-aaa.zip
cd 1.4_server
./build-aaa-image.sh
```

### 从镜像运行容器

直接使用镜像内置文件运行：

```sh
docker run -d \
  --name at-1.4-aaa \
  -p 8101:8101 \
  -p 9101:9101 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  ringotangs/at-1.4-aaa:0.1
```

挂载宿主机目录运行，便于查看和修改 `/app` 内文件：

```sh
mkdir -p /data/at-1.4/aaa

docker run -d \
  --name at-1.4-aaa \
  -p 8101:8101 \
  -p 9101:9101 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  -v /data/at-1.4/aaa:/app \
  ringotangs/at-1.4-aaa:0.1
```

第一次挂载空目录时，容器会把镜像内置文件复制到 `/data/at-1.4/aaa`。后续重启时，只要目录非空，就不会覆盖宿主机上已经修改过的文件。

常用管理命令：

```sh
docker logs -f at-1.4-aaa
docker stop at-1.4-aaa
docker start at-1.4-aaa
docker rm at-1.4-aaa
```

## 后续服务

后续添加 CCS、DBA、GS 镜像时，按本 README 的结构补充镜像名、构建脚本、端口、挂载目录、环境变量和运行命令。
