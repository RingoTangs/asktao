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
