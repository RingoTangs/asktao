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
