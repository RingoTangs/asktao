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
