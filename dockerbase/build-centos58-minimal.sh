#!/bin/bash
set -e
set -o pipefail

IMAGE_NAME="ringotangs/centos58:0.1"

WORKDIR="/root/centos58-docker-build"
ROOTFS="${WORKDIR}/rootfs"
REPO_FILE="${WORKDIR}/CentOS-Base.repo"

# 默认使用阿里云 CentOS Vault，避免 vault.centos.org 太慢
VAULT_BASE="http://mirrors.aliyun.com/centos-vault/5.8"

# 最小化基础包
# 保留 yum/rpm，方便后续基于该基础镜像继续安装软件
BASE_PACKAGES="
bash
coreutils
yum
rpm
passwd
setup
filesystem
glibc
centos-release
tar
gzip
which
"

# 必须安装的 32 位兼容库
# 注意：
# - glibc.i686 在 CentOS 5.8 中可用
# - libstdc++.i686 在 CentOS 5.8 中通常不存在，实际 32 位包多为 libstdc++.i386
REQUIRED_32_PACKAGES="
glibc.i686
libgcc.i386
"

cleanup_mounts() {
  set +e
  mountpoint -q "${ROOTFS}/proc" && umount -lf "${ROOTFS}/proc"
  mountpoint -q "${ROOTFS}/sys" && umount -lf "${ROOTFS}/sys"
  mountpoint -q "${ROOTFS}/dev" && umount -lf "${ROOTFS}/dev"
  set -e
}

trap cleanup_mounts EXIT

run_yum_host() {
  yum \
    --installroot="${ROOTFS}" \
    --releasever=5.8 \
    --disablerepo="*" \
    --enablerepo=base \
    --enablerepo=updates \
    --enablerepo=extras \
    -c "${REPO_FILE}" \
    "$@"
}

run_yum_chroot() {
  chroot "${ROOTFS}" /usr/bin/yum "$@"
}

install_libstdcxx_32_host() {
  echo "==> 安装 32 位 libstdc++：优先 libstdc++.i686，失败则回退 libstdc++.i386..."

  if run_yum_host -y install "libstdc++.i686"; then
    echo "==> 已安装 libstdc++.i686"
  else
    echo "==> libstdc++.i686 不可用，尝试安装 libstdc++.i386..."
    run_yum_host -y install "libstdc++.i386"
  fi
}

install_libstdcxx_32_chroot() {
  echo "==> chroot 内安装 32 位 libstdc++：优先 libstdc++.i686，失败则回退 libstdc++.i386..."

  if run_yum_chroot -y install "libstdc++.i686"; then
    echo "==> chroot 内已安装 libstdc++.i686"
  else
    echo "==> chroot 内 libstdc++.i686 不可用，尝试安装 libstdc++.i386..."
    run_yum_chroot -y install "libstdc++.i386"
  fi
}

echo "==> 检查当前用户..."
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: 请使用 root 执行，或者用 sudo 执行："
  echo "sudo $0"
  exit 1
fi

echo "==> 检查 Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: 未找到 docker，请先安装 docker"
  exit 1
fi

echo "==> 检查 yum..."
if ! command -v yum >/dev/null 2>&1; then
  echo "ERROR: 未找到 yum"
  exit 1
fi

echo "==> 构建目标镜像：${IMAGE_NAME}"

echo "==> 清理旧构建目录..."
cleanup_mounts
rm -rf "${WORKDIR}"
mkdir -p "${ROOTFS}"
mkdir -p "${WORKDIR}"

echo "==> 生成 CentOS 5.8 Vault yum 源..."
cat > "${REPO_FILE}" <<EOF
[base]
name=CentOS-5.8 - Base
baseurl=${VAULT_BASE}/os/x86_64/
enabled=1
gpgcheck=0
timeout=300
retries=10
minrate=1

[updates]
name=CentOS-5.8 - Updates
baseurl=${VAULT_BASE}/updates/x86_64/
enabled=1
gpgcheck=0
timeout=300
retries=10
minrate=1

[extras]
name=CentOS-5.8 - Extras
baseurl=${VAULT_BASE}/extras/x86_64/
enabled=1
gpgcheck=0
timeout=300
retries=10
minrate=1
EOF

echo "==> 第一步：使用宿主机 yum 安装 CentOS 5.8 最小 rootfs..."
run_yum_host -y install ${BASE_PACKAGES}

echo "==> 第二步：安装必须的 32 位兼容库..."
run_yum_host -y install ${REQUIRED_32_PACKAGES}
install_libstdcxx_32_host

echo "==> 写入容器内 yum 源..."
mkdir -p "${ROOTFS}/etc/yum.repos.d"
cp "${REPO_FILE}" "${ROOTFS}/etc/yum.repos.d/CentOS-Base.repo"

echo "==> 写入 DNS 配置..."
cat > "${ROOTFS}/etc/resolv.conf" <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

echo "==> 写入空 fstab..."
cat > "${ROOTFS}/etc/fstab" <<EOF
# empty for container
EOF

echo "==> 设置默认 PATH..."
mkdir -p "${ROOTFS}/etc/profile.d"
cat > "${ROOTFS}/etc/profile.d/docker-path.sh" <<'EOF'
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
EOF

echo "==> 挂载 chroot 需要的目录..."
mkdir -p "${ROOTFS}/proc" "${ROOTFS}/sys" "${ROOTFS}/dev"
mount -t proc proc "${ROOTFS}/proc"
mount --bind /sys "${ROOTFS}/sys"
mount --bind /dev "${ROOTFS}/dev"

echo "==> 删除 CentOS 7 宿主机生成的不兼容 rpmdb..."
rm -f "${ROOTFS}/var/lib/rpm/"__db*
rm -f "${ROOTFS}/var/lib/rpm/Packages"
rm -f "${ROOTFS}/var/lib/rpm/Basenames"
rm -f "${ROOTFS}/var/lib/rpm/Conflictname"
rm -f "${ROOTFS}/var/lib/rpm/Dirnames"
rm -f "${ROOTFS}/var/lib/rpm/Filemd5s"
rm -f "${ROOTFS}/var/lib/rpm/Group"
rm -f "${ROOTFS}/var/lib/rpm/Installtid"
rm -f "${ROOTFS}/var/lib/rpm/Name"
rm -f "${ROOTFS}/var/lib/rpm/Obsoletename"
rm -f "${ROOTFS}/var/lib/rpm/Providename"
rm -f "${ROOTFS}/var/lib/rpm/Provideversion"
rm -f "${ROOTFS}/var/lib/rpm/Pubkeys"
rm -f "${ROOTFS}/var/lib/rpm/Requirename"
rm -f "${ROOTFS}/var/lib/rpm/Requireversion"
rm -f "${ROOTFS}/var/lib/rpm/Sha1header"
rm -f "${ROOTFS}/var/lib/rpm/Sigmd5"
rm -f "${ROOTFS}/var/lib/rpm/Triggername"

echo "==> 使用 CentOS 5 自己的 rpm 初始化 rpmdb..."
chroot "${ROOTFS}" /bin/rpm --initdb

echo "==> 使用 CentOS 5 自己的 yum 重新登记基础包..."
run_yum_chroot -y install ${BASE_PACKAGES}

echo "==> 使用 CentOS 5 自己的 yum 重新登记 32 位兼容库..."
run_yum_chroot -y install ${REQUIRED_32_PACKAGES}
install_libstdcxx_32_chroot

echo "==> 验证 chroot 内 rpmdb 和 32 位库..."
chroot "${ROOTFS}" /bin/rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' \
  | egrep 'glibc|libstdc\+\+|libgcc' \
  | sort

echo "==> 清理 yum 缓存..."
run_yum_chroot -y clean all || true

echo "==> 卸载 chroot 挂载目录..."
cleanup_mounts

echo "==> 清理临时文件..."
rm -rf "${ROOTFS}/var/cache/yum/"*
rm -rf "${ROOTFS}/tmp/"*
rm -rf "${ROOTFS}/var/tmp/"*
rm -rf "${ROOTFS}/root/.bash_history"
rm -f "${ROOTFS}/var/lib/rpm/"__db*

echo "==> 导入 Docker 镜像：${IMAGE_NAME}"
tar --numeric-owner -C "${ROOTFS}" -c . | docker import - "${IMAGE_NAME}"

echo "==> 验证镜像系统版本..."
docker run --rm "${IMAGE_NAME}" cat /etc/redhat-release

echo "==> 验证镜像架构..."
docker image inspect "${IMAGE_NAME}" --format '{{.Os}}/{{.Architecture}}'

echo "==> 验证 rpmdb 和 32 位兼容库..."
docker run --rm "${IMAGE_NAME}" /bin/bash -c \
  "rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | egrep 'glibc|libstdc\+\+|libgcc' | sort"

echo "==> 验证 32 位 libc..."
docker run --rm "${IMAGE_NAME}" /bin/bash -c 'ls -l /lib/libc.so.6'

echo "==> 验证 32 位 libstdc++..."
docker run --rm "${IMAGE_NAME}" /bin/bash -c 'ls -l /usr/lib/libstdc++.so.6'

echo "==> 测试 bash..."
docker run --rm "${IMAGE_NAME}" /bin/bash -c 'echo "CentOS 5.8 minimal Docker image is ready."'

echo "==> 测试 yum repo..."
docker run --rm "${IMAGE_NAME}" yum repolist || true

echo
echo "=================================================="
echo "构建完成"
echo
echo "镜像名称："
echo "  ${IMAGE_NAME}"
echo
echo "进入容器："
echo "  docker run --rm -it ${IMAGE_NAME} /bin/bash"
echo
echo "验证 32 位兼容库："
echo "  docker run --rm ${IMAGE_NAME} rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\\n' | egrep 'glibc|libstdc\\+\\+|libgcc' | sort"
echo
echo "推送到 Docker Hub："
echo "  docker login"
echo "  docker push ${IMAGE_NAME}"
echo
echo "如果 CentOS 7.9 无法连接 Docker Hub，可以导出给 MacBook 推送："
echo "  docker save ${IMAGE_NAME} -o centos58-0.1.tar"
echo "  gzip centos58-0.1.tar"
echo
echo "=================================================="