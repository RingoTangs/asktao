# 一、导出镜像

```sh
docker save ringotangs/at-centos79:0.1 -o at-centos79-0.1.tar
```

# 二、加载镜像

```sh
docker load -i at-centos79-0.1.tar
```

# 三、macOS 上推送到 Docker Hub

先登录：

```sh
docker login
```

然后推送：

```sh
docker push ringotangs/at-centos79:0.1
```
