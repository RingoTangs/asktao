# AskTao 1.4 服务镜像导出和发布

本文档记录 AAA、DBA、CCS、GS 服务镜像的导出、加载和推送 Docker Hub 命令。执行前请先在服务器上完成对应镜像构建。

# 一、导出镜像

导出单个镜像：

```sh
docker save ringotangs/at-1.4-aaa:0.1 -o at-1.4-aaa-0.1.tar
docker save ringotangs/at-1.4-dba:0.1 -o at-1.4-dba-0.1.tar
docker save ringotangs/at-1.4-ccs:0.1 -o at-1.4-ccs-0.1.tar
docker save ringotangs/at-1.4-gs:0.1 -o at-1.4-gs-0.1.tar
```

也可以一次导出全部服务镜像：

```sh
docker save \
  ringotangs/at-1.4-aaa:0.1 \
  ringotangs/at-1.4-dba:0.1 \
  ringotangs/at-1.4-ccs:0.1 \
  ringotangs/at-1.4-gs:0.1 \
  -o at-1.4-server-0.1.tar
```

# 二、加载镜像

加载单个镜像：

```sh
docker load -i at-1.4-aaa-0.1.tar
docker load -i at-1.4-dba-0.1.tar
docker load -i at-1.4-ccs-0.1.tar
docker load -i at-1.4-gs-0.1.tar
```

如果使用了全部服务镜像包：

```sh
docker load -i at-1.4-server-0.1.tar
```

# 三、推送到 Docker Hub

先登录：

```sh
docker login
```

然后推送：

```sh
docker push ringotangs/at-1.4-aaa:0.1
docker push ringotangs/at-1.4-dba:0.1
docker push ringotangs/at-1.4-ccs:0.1
docker push ringotangs/at-1.4-gs:0.1
```

# 四、确认镜像

查看本机镜像：

```sh
docker images | grep 'ringotangs/at-1.4'
```

确认镜像可以拉取：

```sh
docker pull ringotangs/at-1.4-aaa:0.1
docker pull ringotangs/at-1.4-dba:0.1
docker pull ringotangs/at-1.4-ccs:0.1
docker pull ringotangs/at-1.4-gs:0.1
```
