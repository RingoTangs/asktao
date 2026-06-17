# AskTao 1.4 服务端 Docker 使用说明

本文档说明如何把 `1.4_server` 里的问道 1.4 服务端程序打包、上传、构建成 Docker 镜像，并运行 AAA、DBA、CCS、GS 容器。第一次操作建议先照着 `TEST.md` 的顺序执行：先 AAA，再 DBA，再 CCS，最后 GS。

## 目录说明

- `aaa/`、`dba/`、`ccs/`、`gs/`：各服务的配置文件和 `pack_data` 资源。
- `runaaa`、`rundba`、`runccs`、`rungs`：各服务启动脚本。
- `magic_Linux32`：服务运行需要的 32 位 Linux 程序。
- `build-*-image.sh`：构建对应服务镜像。
- `package-*.sh`：把构建镜像需要的文件打成 zip，方便上传服务器。
- `TEST.md`：带真实测试参数的容器启动命令。

## 服务和镜像

| 服务 | 镜像 | 基础镜像 | 端口 | 默认挂载目录 |
| --- | --- | --- | --- | --- |
| AAA | `ringotangs/at-1.4-aaa:0.1` | `ringotangs/at-centos79:0.1` | `8101`、`9101` | `/data/at-1.4/aaa` |
| DBA | `ringotangs/at-1.4-dba:0.1` | `ringotangs/at-centos79:0.1` | `8120`、`9120` | `/data/at-1.4/dba` |
| CCS | `ringotangs/at-1.4-ccs:0.1` | `ringotangs/at-centos79:0.1` | `8110`、`9110` | `/data/at-1.4/ccs` |
| GS | `ringotangs/at-1.4-gs:0.1` | `ringotangs/at-centos58:0.1` | 示例 `8160` | `/data/at-1.4/gs1` |

服务器上需要先有对应基础镜像。AAA、DBA、CCS 使用 CentOS 7.9 基础镜像；GS 使用 CentOS 5.8 基础镜像。

## 打包上传

在本地仓库执行打包脚本，会在 `1.4_server` 目录生成 zip 文件：

```sh
cd 1.4_server
./package-aaa.sh
./package-dba.sh
./package-ccs.sh
./package-gs.sh
```

把生成的 zip 上传到服务器，例如 `asktao-1.4-aaa.zip`、`asktao-1.4-gs.zip`。在服务器上解压：

```sh
unzip asktao-1.4-aaa.zip
cd 1.4_server
```

如果上传多个 zip，建议都解压到同一个父目录，让它们合并到同一个 `1.4_server` 目录。

## 构建镜像

进入服务器上的 `1.4_server` 后，按需构建镜像：

```sh
./build-aaa-image.sh
./build-dba-image.sh
./build-ccs-image.sh
./build-gs-image.sh
```

构建脚本会检查必需文件是否存在，然后执行 `docker build`。如果提示缺少基础镜像，需要先在服务器上准备好 `ringotangs/at-centos79:0.1` 或 `ringotangs/at-centos58:0.1`。

## 配置和挂载规则

容器内工作目录是 `/app`。推荐把宿主机目录挂载到 `/app`，这样容器初始化后的配置和资源文件能直接在宿主机查看和修改。

首次启动时，如果宿主机挂载目录是空的，容器会把镜像内置文件复制到该目录。之后重启容器时，已有文件不会被覆盖。只有显式设置 `RESET_CONFIG=1` 时，脚本才会从镜像模板恢复对应 `.ini` 配置文件。

`.ini` 文件按 GBK 编码处理。编辑 `aaa.ini`、`dba.ini`、`ccs.ini`、`game_server.ini` 时，不要随意转换成 UTF-8，否则中文可能乱码。

## 运行容器

先创建挂载目录：

```sh
mkdir -p /data/at-1.4/aaa
mkdir -p /data/at-1.4/dba
mkdir -p /data/at-1.4/ccs
mkdir -p /data/at-1.4/gs1
```

运行 AAA：

```sh
docker run -itd \
  --name at-1.4-aaa \
  -p 8101:8101 \
  -p 9101:9101 \
  -e DB_HOST=47.97.104.166 \
  -e DB_USER=asktao \
  -e DB_PASSWORD=123456 \
  -v /data/at-1.4/aaa:/app \
  ringotangs/at-1.4-aaa:0.1
```

运行 DBA：

```sh
docker run -itd \
  --name at-1.4-dba \
  -p 8120:8120 \
  -p 9120:9120 \
  -e DB_HOST=47.97.104.166 \
  -e DB_USER=asktao \
  -e DB_PASSWORD=123456 \
  -e AAA_ADDR=47.97.104.166 \
  -v /data/at-1.4/dba:/app \
  ringotangs/at-1.4-dba:0.1
```

运行 CCS：

```sh
docker run -itd \
  --name at-1.4-ccs \
  -p 8110:8110 \
  -p 9110:9110 \
  -e DB_HOST=47.97.104.166 \
  -e DB_USER=asktao \
  -e DB_PASSWORD=123456 \
  -e AAA_ADDR=47.97.104.166 \
  -v /data/at-1.4/ccs:/app \
  ringotangs/at-1.4-ccs:0.1
```

运行 GS 一线：

```sh
docker run -itd \
  --name at-1.4-gs1 \
  -p 8160:8160 \
  -e GS_NAME=试剑内测一线 \
  -e AAA_ADDR=47.97.104.166 \
  -v /data/at-1.4/gs1:/app \
  ringotangs/at-1.4-gs:0.1
```

`DB_HOST`、`DB_USER`、`DB_PASSWORD` 会写入 AAA、DBA、CCS 的数据库配置。`AAA_ADDR` 会写入 DBA、CCS、GS 的 AAA 地址。`GS_NAME` 会写入 GS 的线路名称，支持中文；GS 脚本会按 GBK 读写 `game_server.ini`。

## 常用管理命令

查看容器状态：

```sh
docker ps -a --filter "name=at-1.4"
```

查看日志：

```sh
docker logs -f at-1.4-aaa
docker logs -f at-1.4-dba
docker logs -f at-1.4-ccs
docker logs -f at-1.4-gs1
```

停止、启动、删除容器：

```sh
docker stop at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
docker start at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
docker rm at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
```

如果要重新创建容器，可以先强制删除旧容器：

```sh
docker rm -f at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
```

## 常见问题

看到 `Initializing missing /app files from image contents...` 不是错误。它表示挂载目录缺少服务文件，容器正在从镜像里复制缺失文件。第一次用空目录启动时会出现这条日志。

修改宿主机 `/data/at-1.4/...` 里的文件后，重启容器不会自动覆盖这些修改。如果想恢复镜像里的默认配置，可以启动容器时加 `-e RESET_CONFIG=1`，但它会覆盖对应 `.ini` 配置文件。

如果环境变量改了但配置没变化，通常是因为挂载目录里已经有旧 `.ini`。可以手动编辑宿主机目录里的配置文件，或者用 `RESET_CONFIG=1` 恢复模板后重新传环境变量。

GS 使用 `ringotangs/at-centos58:0.1`，里面的 Python 是 2.4.3。GS 启动脚本只依赖 Python 内置库 `os`、`sys`、`codecs`，并会检查 GBK codec 是否可用。
