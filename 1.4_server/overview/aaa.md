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
