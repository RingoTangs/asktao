```
docker run -d \
  --name mysql55 \
  -p 3306:3306 \
  -v /data/at-1.4/mysql/config:/etc/mysql/conf.d \
  -v /data/at-1.4/mysql/data:/var/lib/mysql \
  -v /data/at-1.4/mysql/logs:/var/log/mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  mysql:5.5.62
```

```
-- 创建用户 asktao，同时支持 localhost 和 %
CREATE USER 'asktao'@'localhost' IDENTIFIED WITH 'mysql_old_password';
CREATE USER 'asktao'@'%' IDENTIFIED WITH 'mysql_old_password';

-- 设置旧密码
SET old_passwords = 1;
SET PASSWORD FOR 'asktao'@'localhost' = PASSWORD('123456');
SET PASSWORD FOR 'asktao'@'%' = PASSWORD('123456');

-- 授予权限（请谨慎使用管理员权限）
GRANT ALL PRIVILEGES ON *.* TO 'asktao'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'asktao'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
```
