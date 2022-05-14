

#安装MySQL
yum remove mysql mysql-server mysql-libs mysql-common mariadb* mysql-community* -y
rm -rf /var/log/mysqld.log
rm -rf /var/lib/mysql
rm -rf /etc/my.cnf

#导入密钥
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

#ubuntu版
#wget -q -O - https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | apt-key add -

yum -y install wget
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum -y install mysql57-community-release-el7-11.noarch.rpm
yum -y install mysql-community-server
systemctl enable mysqld

#创建数据目录
mkdir -p /data/mysql

#添加mysql配置
cat>/etc/my.cnf<<"EOF"
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
port = 3306
datadir=/data/mysql
skip-name-resolve
default-storage-engine = InnoDB
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# 字符集配置
character_set_server=utf8

# gtid配置
server_id = 1
#gtid_mode = on
#enforce-gtid-consistency = true
#log-slave-updates = on

#binlog日志配置
binlog_format = row
log_bin = /data/mysql/mysql-bin
expire_logs_days = 30
#max_binlog_size = 100m
#binlog_cache_size = 4m
#max_binlog_cache_size = 512m

# 连接数限制
max_connections = 500
max_connect_errors = 20
back_log = 500
open_files_limit = 65535
interactive_timeout = 3600
wait_timeout = 3600
max_allowed_packet=1000M
lower_case_table_names=1

#自动提交
autocommit=1
sync_binlog=1

# InnoDB 优化
innodb_buffer_pool_size=2G
innodb_log_file_size = 256M
innodb_log_buffer_size = 4M
innodb_log_buffer_size = 3M
innodb_data_file_path = ibdata1:100M:autoextend
innodb_log_files_in_group = 3
innodb_open_files = 800
innodb_file_per_table = 1
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 1
innodb_lock_wait_timeout = 120
innodb_strict_mode=1
innodb_large_prefix = on

#自增配置
sql_mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
EOF

#重启数据库
systemctl restart mysqld

#定义mysql默认密码为变量
PASSWORD=$(less /var/log/mysqld.log | grep 'temporary password' | grep -o -E ': .+' | awk '{print $2}')

#修改mysql密码
mysql --connect-expired-password -uroot -p$PASSWORD -e "set global validate_password_policy=0;"
mysql --connect-expired-password -uroot -p$PASSWORD -e "set global validate_password_length=4;"
mysqladmin -uroot -p$PASSWORD password hKBY^LDkBGTCimMl

#mysql忘记密码
#echo "skip-grant-tables">>/etc/my.cnf
#systemctl restart mysqld
#mysql -e "update mysql.user set authentication_string=password('hKBY^LDkBGTCimMl') where user='root' and Host = 'localhost';"
#mysql -uroot -phKBY^LDkBGTCimMl -e 'flush privileges;'
#mysql -uroot -phKBY^LDkBGTCimMl -e "alter user 'root'@'localhost' identified by 'hKBY^LDkBGTCimMl';"
#sed -i 's/skip-grant-tables/#skip-grant-tables/g' /etc/my.cnf
#systemctl restart mysqld

#授予mysql远程权限(root)
#mysql -uroot -phKBY^LDkBGTCimMl -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%" IDENTIFIED BY "hKBY^LDkBGTCimMl";'
mysql -uroot -phKBY^LDkBGTCimMl -e 'create database cms;'
#mysql -uroot -phKBY^LDkBGTCimMl -e 'create database wordpress;'
#mysql -uroot -phKBY^LDkBGTCimMl -e 'Flush privileges;'

#导入数据库
#mysql -uroot -phKBY^LDkBGTCimMl cms < /home/wwwroot/cms/zycms.sql

#服务启动
systemctl enable nginx php-fpm mysqld
systemctl restart nginx php-fpm mysqld

