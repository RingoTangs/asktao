# AskTao 1.4 Docker 镜像测试命令

以下命令用于在测试服务器上启动 AAA、DBA、CCS 和 GS 容器。命令会把容器内 `/app` 挂载到宿主机 `/data/at-1.4/...`，首次启动空目录时会自动初始化服务文件。

## 测试参数

```sh
DB_HOST=47.97.104.166
DB_USER=asktao
DB_PASSWORD=123456
AAA_ADDR=47.97.104.166
GS_NAME=试剑内测一线
```

## 准备挂载目录

```sh
mkdir -p /data/at-1.4/aaa
mkdir -p /data/at-1.4/dba
mkdir -p /data/at-1.4/ccs
mkdir -p /data/at-1.4/gs
```

## 运行 AAA

```sh
docker rm -f at-1.4-aaa 2>/dev/null || true

docker run -itd \
  --name at-1.4-aaa \
  -p 8101:8101 \
  -p 9101:9101 \
  -e DB_HOST=47.97.104.166 \
  -e DB_USER=asktao \
  -e DB_PASSWORD=123456 \
  -v /data/at-1.4/aaa:/app \
  ringotangs/at-1.4-aaa:0.1

docker logs -f at-1.4-aaa
```

## 运行 DBA

```sh
docker rm -f at-1.4-dba 2>/dev/null || true

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

docker logs -f at-1.4-dba
```

## 运行 CCS

```sh
docker rm -f at-1.4-ccs 2>/dev/null || true

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

docker logs -f at-1.4-ccs
```

## 运行 GS

```sh
docker rm -f at-1.4-gs1 2>/dev/null || true

docker run -itd \
  --name at-1.4-gs1 \
  -p 8160:8160 \
  -e GS_NAME=试剑内测一线 \
  -e AAA_ADDR=47.97.104.166 \
  -v /data/at-1.4/gs:/app \
  ringotangs/at-1.4-gs:0.1

docker logs -f at-1.4-gs1
```

## 查看状态

```sh
docker ps -a --filter "name=at-1.4"
```

## 停止和清理

```sh
docker stop at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
docker rm at-1.4-aaa at-1.4-dba at-1.4-ccs at-1.4-gs1
```
