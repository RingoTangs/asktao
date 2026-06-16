#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="ringotangs/at-centos79:0.1"
ALIYUN_CENTOS_VAULT="https://mirrors.aliyun.com/centos-vault/7.9.2009"
BUILD_DIR="/root/centos79-docker-build"

echo "构建镜像: ${IMAGE_NAME}"
echo "使用 yum 源: ${ALIYUN_CENTOS_VAULT}"
echo "构建目录: ${BUILD_DIR}"

if [ "$(id -u)" -ne 0 ]; then
  echo "错误: 当前脚本需要 root 权限执行，因为构建目录是 ${BUILD_DIR}"
  echo "请使用: sudo ./build-centos79-i686.sh"
  exit 1
fi

command -v docker >/dev/null 2>&1 || {
  echo "错误: 未找到 docker 命令"
  exit 1
}

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cat > Dockerfile <<'EOF'
FROM centos:7.9.2009

LABEL org.opencontainers.image.title="CentOS 7.9.2009 with i686 libraries" \
      org.opencontainers.image.description="CentOS 7.9.2009 base image including glibc.i686 and libstdc++.i686"

RUN set -eux; \
    rm -f /etc/yum.repos.d/*.repo; \
    printf '%s\n' \
'[base]' \
'name=CentOS-7.9.2009 - Base - Aliyun Vault' \
'baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/' \
'enabled=1' \
'gpgcheck=1' \
'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7' \
'' \
'[updates]' \
'name=CentOS-7.9.2009 - Updates - Aliyun Vault' \
'baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/' \
'enabled=1' \
'gpgcheck=1' \
'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7' \
'' \
'[extras]' \
'name=CentOS-7.9.2009 - Extras - Aliyun Vault' \
'baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/' \
'enabled=1' \
'gpgcheck=1' \
'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7' \
    > /etc/yum.repos.d/CentOS-Vault-7.9.2009-Aliyun.repo; \
    yum clean all; \
    yum -y makecache; \
    yum -y install --setopt=tsflags=nodocs glibc.i686 libstdc++.i686; \
    rpm -q glibc.i686 libstdc++.i686; \
    yum clean all; \
    rm -rf /var/cache/yum /tmp/* /var/tmp/*

CMD ["/bin/bash"]
EOF

echo
echo "开始 docker build..."
docker build -t "${IMAGE_NAME}" .

echo
echo "开始验证镜像..."
docker run --rm "${IMAGE_NAME}" bash -lc '
set -e

echo "系统版本:"
cat /etc/centos-release

echo
echo "CPU 架构:"
uname -m

echo
echo "检查 i686 依赖:"
rpm -q glibc.i686
rpm -q libstdc++.i686

echo
echo "检查 32 位动态加载器:"
ls -l /lib/ld-linux.so.2

echo
echo "验证通过"
'

echo
echo "构建完成: ${IMAGE_NAME}"
echo
echo "Dockerfile 保留在: ${BUILD_DIR}/Dockerfile"
echo
echo "运行测试:"
echo "docker run --rm -it ${IMAGE_NAME} bash"
echo
echo "推送到 Docker Hub:"
echo "docker push ${IMAGE_NAME}"