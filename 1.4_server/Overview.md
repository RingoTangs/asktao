# Docker Hub Overview

本文档包含 AskTao 1.4 AAA、DBA、CCS、GS 四个 Docker Hub 镜像仓库的 Overview 内容。发布时分别复制到对应 Docker Hub 仓库页面。

## ringotangs/at-1.4-aaa

````md
# AskTao 1.4 AAA Server

AskTao（问道）1.4 服务端 AAA 镜像。

## Image

```sh
ringotangs/at-1.4-aaa:0.1
```

## Base Image

```sh
ringotangs/at-centos79:0.1
```

## Ports

- `8101`
- `9101`

## Run

```sh
mkdir -p /data/at-1.4/aaa

docker run -itd \
  --name at-1.4-aaa \
  -p 8101:8101 \
  -p 9101:9101 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  -v /data/at-1.4/aaa:/app \
  ringotangs/at-1.4-aaa:0.1
```

## Notes

- Container workdir is `/app`.
- If `/app` is empty, required runtime files are initialized from the image.
- Existing mounted files are not overwritten.
- `.ini` files use GBK encoding.
````

## ringotangs/at-1.4-dba

````md
# AskTao 1.4 DBA Server

AskTao（问道）1.4 服务端 DBA 镜像。

## Image

```sh
ringotangs/at-1.4-dba:0.1
```

## Base Image

```sh
ringotangs/at-centos79:0.1
```

## Ports

- `8120`
- `9120`

## Run

```sh
mkdir -p /data/at-1.4/dba

docker run -itd \
  --name at-1.4-dba \
  -p 8120:8120 \
  -p 9120:9120 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  -e AAA_ADDR=your-aaa-host \
  -v /data/at-1.4/dba:/app \
  ringotangs/at-1.4-dba:0.1
```

## Notes

- Container workdir is `/app`.
- `DB_HOST`, `DB_USER`, and `DB_PASSWORD` are written to the DBA config.
- `AAA_ADDR` is written to the DBA config.
- `.ini` files use GBK encoding.
````

## ringotangs/at-1.4-ccs

````md
# AskTao 1.4 CCS Server

AskTao（问道）1.4 服务端 CCS 镜像。

## Image

```sh
ringotangs/at-1.4-ccs:0.1
```

## Base Image

```sh
ringotangs/at-centos79:0.1
```

## Ports

- `8110`
- `9110`

## Run

```sh
mkdir -p /data/at-1.4/ccs

docker run -itd \
  --name at-1.4-ccs \
  -p 8110:8110 \
  -p 9110:9110 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  -e AAA_ADDR=your-aaa-host \
  -v /data/at-1.4/ccs:/app \
  ringotangs/at-1.4-ccs:0.1
```

## Notes

- Container workdir is `/app`.
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`, and `AAA_ADDR` are written to the CCS config.
- Existing mounted files are not overwritten.
- `.ini` files use GBK encoding.
````

## ringotangs/at-1.4-gs

````md
# AskTao 1.4 GS Server

AskTao（问道）1.4 服务端 GS 镜像。

## Image

```sh
ringotangs/at-1.4-gs:0.1
```

## Base Image

```sh
ringotangs/at-centos58:0.1
```

## Port Example

- `8160`

## Run

```sh
mkdir -p /data/at-1.4/gs1

docker run -itd \
  --name at-1.4-gs1 \
  -p 8160:8160 \
  -e GS_NAME=your-gs-name \
  -e AAA_ADDR=your-aaa-host \
  -v /data/at-1.4/gs1:/app \
  ringotangs/at-1.4-gs:0.1
```

## Notes

- Container workdir is `/app`.
- `GS_NAME` is written to `game_server.ini`.
- `AAA_ADDR` is written to `game_server.ini`.
- `game_server.ini` is read and written as GBK, so Chinese GS names are supported.
- Existing mounted files are not overwritten.
````
