# AskTao 1.4 MySQL 部署说明

本文档说明如何使用 Docker 启动 AskTao 1.4 服务端使用的 MySQL 数据库。当前使用 `mysql:5.5.62`，用于兼容较老的 MySQL 客户端认证方式。

## 一、准备目录

数据库配置、数据和日志建议挂载到宿主机，方便备份和排查问题。

```sh
mkdir -p /data/at-1.4/mysql/config
mkdir -p /data/at-1.4/mysql/data
mkdir -p /data/at-1.4/mysql/logs
```

## 二、启动 MySQL 容器

把 `your-root-password` 替换成你自己的 root 密码。

```sh
docker run -d \
  --name at-1.4-mysql \
  -p 3306:3306 \
  -v /data/at-1.4/mysql/config:/etc/mysql/conf.d \
  -v /data/at-1.4/mysql/data:/var/lib/mysql \
  -v /data/at-1.4/mysql/logs:/var/log/mysql \
  -e MYSQL_ROOT_PASSWORD=your-root-password \
  mysql:5.5.62
```

查看容器是否启动成功：

```sh
docker ps -a --filter "name=at-1.4-mysql"
docker logs -f at-1.4-mysql
```

## 三、登录 MySQL

```sh
docker exec -it at-1.4-mysql mysql -uroot -p
```

输入上一步设置的 root 密码后进入 MySQL 命令行。

## 四、创建 AskTao 数据库用户

下面示例创建 `asktao` 用户。把 `your-db-password` 替换成你自己的数据库密码，并和 AAA、DBA、CCS 容器里的 `DB_PASSWORD` 保持一致。

```sql
SET old_passwords = 1;

CREATE USER 'asktao'@'localhost' IDENTIFIED WITH 'mysql_old_password';
CREATE USER 'asktao'@'%' IDENTIFIED WITH 'mysql_old_password';

SET PASSWORD FOR 'asktao'@'localhost' = PASSWORD('your-db-password');
SET PASSWORD FOR 'asktao'@'%' = PASSWORD('your-db-password');

GRANT ALL PRIVILEGES ON *.* TO 'asktao'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'asktao'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
```

说明：

- `'asktao'@'localhost'` 用于本机连接。
- `'asktao'@'%'` 用于其他容器或远程主机连接。
- `SET old_passwords = 1` 和 `PASSWORD(...)` 用于生成旧格式密码，兼容 AskTao 1.4 服务端的旧 MySQL 客户端。
- `GRANT ALL PRIVILEGES ON *.*` 权限较大，适合测试和私有部署；生产环境可按实际库表收窄权限。

## 五、验证连接

在宿主机或能访问数据库的机器上测试：

```sh
mysql -h your-db-host -P 3306 -uasktao -p
```

如果宿主机没有安装 `mysql` 客户端，也可以用容器内客户端测试：

```sh
docker exec -it at-1.4-mysql mysql -uasktao -p
```

登录成功后可以查看用户：

```sql
SELECT User, Host FROM mysql.user WHERE User = 'asktao';
```

## 六、常用管理命令

停止、启动和删除容器：

```sh
docker stop at-1.4-mysql
docker start at-1.4-mysql
docker rm at-1.4-mysql
```

查看日志：

```sh
docker logs -f at-1.4-mysql
```

进入容器：

```sh
docker exec -it at-1.4-mysql bash
```

## 七、常见问题

如果 `3306` 端口被占用，可以改宿主机端口，例如：

```sh
-p 3307:3306
```

此时其他服务连接数据库时，端口也要使用 `3307`。

如果 `/data/at-1.4/mysql/data` 已经初始化过，修改 `MYSQL_ROOT_PASSWORD` 不会重置 root 密码。这个环境变量只在首次初始化数据目录时生效。

如果 AskTao 服务连接数据库失败，优先检查：

- `DB_HOST` 是否能访问到 MySQL 容器所在主机。
- `DB_USER` 是否为 `asktao`。
- `DB_PASSWORD` 是否和上面设置的 `your-db-password` 一致。
- 服务器防火墙或安全组是否放通 `3306`。
- MySQL 用户是否创建了 `'asktao'@'%'`。
