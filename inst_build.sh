#! /bin/bash

# # Allow only non-root execution
# if [ `id|sed -e s/uid=//g -e s/\(.*//g` -eq 0 ]; then
#     echo "This script requires non-root privileges"
#     exit 1
# fi

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

###########################################################
# Only set REDIS_HOME if not already set
[ -z "$build_path" ] && build_path=`cd "$PRGDIR" >/dev/null; pwd`

build_path=/srv/build
export build_path

#source放置源码文件
build_src=$build_path/source && mkidr -p $build_src

#packages放置rpm文件：
build_pkgs=$build_path/packages && mkdir -p $build_pkgs
#放置基本工具，也应该移到$build_pkgs
build_tool=$build_path/tool && mkdir -p $build_tool

# 〖路径尽可能用单词全称，变量用简称〗
#workspace/具体项目，方式编译中间成果项目文件
build_ws=$build_path/workspace && mkdir -p $build_ws

###########################################################
#具体项目，如fdfs-fastdfs,ngx-nginx
build_p_fdfs=$build_ws/fastdfs && mkdir -p $build_p_fdfs
build_p_ngx=$build_ws/nginx && mkdir -p $build_p_ngx
build_p_redis=$build_ws/redis && mkdir -p $build_p_redis

###########################################################
#〖注意采用yum安装rpm文件时，需要指定包名，不能简单的用 路径/*.rpm，会安装不符合要求的包造成系统混乱！〗
# 下载必要的依赖包rpm文件，并安装，安装中不要贪多，够用就好！
# 将 $build_tool 与 $build_pkgs 区分开，是未了便于后续复制 tool 需要的包，应该将 $build_tool 合并到 $build_pkgs 中，作为本工具的工具仓库

cd $build_tool
yum -y install --downloadonly --downloaddir=$build_tool/ git
yum -y localinstall $build_tool/git-*.rpm

yum -y install --downloadonly --downloaddir=$build_tool/ wget
yum -y localinstall $build_tool/wget-*.rpm

yum -y install --downloadonly --downloaddir=$build_tool/ xz
yum -y localinstall $build_tool/xz-*.rpm

yum -y install --downloadonly --downloaddir=$build_tool/ unzip
yum -y localinstall $build_tool/unzip-*.rpm

#table补齐
yum -y install --downloadonly --downloaddir=$build_tool/ policycoreutils-python
yum -y localinstall $build_tool/policycoreutils-python-*.rpm

###########################################################
# 下载源码 from git master分支git → 手动打包为 tar.gz
# 或直接下载src包，可能格式主要有：tar.gz、tgz、xz.gz、zip等
###########################################################

#下载fastdfs相关文件

#############################
# 只拉取最新的一次commit:
# $ git clone --depth=1 xxxxxx
# git clone --depth=1之后拉取其他分支
# $ git remote set-branches origin 'remote_branch_name'
# $ git fetch --depth 1 origin remote_branch_name
# $ git checkout remote_branch_name
#############################
# https://www.jianshu.com/p/14de2eb11c0f

# fastdfs:
cd $build_src
git clone --depth=1 https://github.com/happyfish100/fastdfs.git
tar -zcf $build_src/fastdfs-5.12.tar.gz --exclude=fastdfs/.git fastdfs

# libfastcommon:
git clone --depth=1 https://github.com/happyfish100/libfastcommon.git
tar -zcf $build_src/libfastcommon-1.40.tar.gz --exclude=libfastcommon/.git libfastcommon

# fastdfs-nginx 相关：
git clone --depth=1 https://github.com/happyfish100/fastdfs-nginx-module.git
tar -zcf $build_src/fastdfs-nginx-module-1.20.tar.gz --exclude=fastdfs-nginx-module/.git fastdfs-nginx-module

cd $build_src
wget -c -nc http://nginx.org/download/nginx-1.15.1.tar.gz
wget -c -nc http://nginx.org/download/nginx-1.17.3.tar.gz

#nginx 相关依赖：gcc gcc-c++ make cmake automake autoconf libtool pcre* zlib openssl openssl-devel
# pcre zlib openssl 采用源码编译时可以去掉


yum -y install --downloadonly --downloaddir=$build_pkgs gcc gcc-c++ make cmake automake autoconf libtool pcre* zlib openssl openssl-devel
yum -y localinstall $build_pkgs/{gcc,gcc-c++,make,cmake,automake,autoconf,libtool,pcre*,zlib,openssl,openssl-devel}-*.rpm

yum -y install --downloadonly --downloaddir=$build_pkgs dbus
yum -y localinstall $build_pkgs/dbus-*.rpm

###################
#采用系统默认的openssl、pcre包编译的nginx经验证在ubuntu19.04中不能用，因此尝试通过下载最新的openssl和pcre源码包来重新编译
# https://www.openssl.org/source/
# http://www.pcre.org/  ftp://ftp.pcre.org/pub/pcre/
# http://www.zlib.net/
# http://ftp.gnu.org/gnu/libtool/

cd $build_src
wget -c -nc https://www.openssl.org/source/openssl-1.1.1c.tar.gz
wget -c -nc ftp://ftp.pcre.org/pub/pcre/pcre-8.43.zip
#wget -c -nc ftp://ftp.pcre.org/pub/pcre/pcre2-10.33.tar.gz
wget -c -nc http://www.zlib.net/zlib-1.2.11.tar.gz
wget -c -nc http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz
wget -c -nc http://nginx.org/download/nginx-1.17.3.tar.gz

# openssl安装方式是：./config --prefix;make && make install
#   或 ./config shared zlib && 在build之前做make depend && make && make install
wget -c -nc https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz
wget -c -nc https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tgz

wget -c -nc https://download.edgewall.org/trac/Trac-1.4.tar.gz
###################

# fastdht
git clone --depth=1 https://github.com/happyfish100/fastdht.git
tar -zcf $build_src/fastdht-2.01.tar.gz --exclude=fastdht/.git fastdht

# Berkeley DB
# download db-4.7.25.tar.gz from website
# http://www.oracle.com/technology/software/products/berkeley-db/index.html

# https://github.com/happyfish100/fastdht/blob/master/INSTALL


###########################################################
# 编译及安装
###########################################################
# 安装根目录，编译后默认程序路径 $dest_path
dest_path=/srv/mstsrv && mkdir -p $dest_path
export dest_path

# 目录 fdfs_home 后续nginx-fdfs编译也需要
fdfs_home=$dest_path/fastdfs
export fdfs_home
###########################################################
# 说明 function 名称两端用_连接，以区分同名变量           #
###########################################################
# build_src -- 源文件压缩包公共位置
# buile_pkgs -- 依赖包 rpm 公共位置
###########################################################
# fdfs执行编译安装代码块： function _build_fdfs_          #
###########################################################
# 注意FastDFS尽可能直接编译到安装目录
function _build_fdfs_()
{
# build_p_fdfs 编译工作目录
# fdfs_home   编译后安装目录

build_p_fdfs=$build_p_fdfs
fdfs_home=$dest_path/fastdfs
###########################################################

#安装lib
#make.sh文件中有DESTDIR这个变量，为空默认root用户编译的安装的时候就在系统根目录下，但普通用户是没有根目录的写入权限的。
export DESTDIR=$fdfs_home

tar -zxf $build_src/libfastcommon-1.40.tar.gz  -C $build_p_fdfs
#修改文件$build_p_fdfs/libfastcommon/src/fast_link_library.sh
flls=$build_p_fdfs/libfastcommon/src/fast_link_library.sh
sed -i.bak "s#/usr/local/lib#${DESTDIR}/usr/lib#g" $flls

cd $build_p_fdfs/libfastcommon
./make.sh
fltm=$build_p_fdfs/libfastcommon/src/tests/Makefile
sed -i.bak "s#/usr/local/include#${DESTDIR}/usr/include#g" $fltm
./make.sh install
cd $fdfs_home

# 配置fastdfs编译条件
tar -zxf $build_src/fastdfs-5.12.tar.gz  -C $build_p_fdfs
cd $build_p_fdfs/fastdfs
cdt="date '+%Y%m%d-%H%M%S-%s'"

#修改make.sh文件
fms=$build_p_fdfs/fastdfs/make.sh
sed -i.bak "s#LIBS=''#LIBS=\"-Wl,-rpath=${DESTDIR}/usr/lib64\"#g" $fms
sed -i     "s#-d /etc/fdfs#-d \$TARGET_CONF_PATH#g" $fms
sed -i     "s#-p /etc/fdfs#-p \$TARGET_CONF_PATH#g" $fms
# #修改common/Makefile文件
fcm=$build_p_fdfs/fastdfs/common/Makefile
sed -i.bak "s#INC_PATH = -I/usr/local/include#INC_PATH = -I${DESTDIR}/usr/include#g" $fcm
sed -i     "s#LIB_PATH = -L/usr/local/lib#LIB_PATH = -L${DESTDIR}/usr/lib64#g" $fcm
sed -i     "s#TARGET_PATH = /usr/local/bin#TARGET_PATH = ${DESTDIR}/usr/bin#g" $fcm
#修改Makefile.in文件
# $build_p_fdfs/fastdfs/tracker/Makefile.in
ftmi=$build_p_fdfs/fastdfs/tracker/Makefile.in
sed -i.bak "s#INC_PATH = -I../common -I/usr/local/include#INC_PATH = -I../common -I${DESTDIR}/usr/include/fastcommon#g" $ftmi
sed -i     "s#LIB_PATH = \$(LIBS) -lfastcommon#LIB_PATH = \$(LIBS) -L${DESTDIR}/usr/lib64 -lfastcommon#g" $ftmi
fsmi=$build_p_fdfs/fastdfs/storage/Makefile.in
sed -i.bak "s#INC_PATH = -I. -Itrunk_mgr -I../common -I../tracker -I../client -Ifdht_client -I/usr/include/fastcommon#INC_PATH = -I. -Itrunk_mgr -I../common -I../tracker -I../client -Ifdht_client -I${DESTDIR}/usr/include/fastcommon#g" $fsmi
sed -i     "s#LIB_PATH = \$(LIBS)  -lfastcommon#LIB_PATH = \$(LIBS) -L${DESTDIR}/usr/lib64 -lfastcommon#g" $fsmi
fcmi=$build_p_fdfs/fastdfs/client/Makefile.in
sed -i.bak "s#INC_PATH = -I../common -I../tracker -I/usr/include/fastcommon#INC_PATH = -I../common -I../tracker -I${DESTDIR}/usr/include/fastcommon#g" $fcmi
sed -i     "s#LIB_PATH = \$(LIBS) -lfastcommon#LIB_PATH = \$(LIBS) -L${DESTDIR}/usr/lib64 -lfastcommon#g" $fcmi

#创建连接，这个连接不能少
ln -s $fdfs_home/usr/include/fastcommon $build_p_fdfs/fastdfs/common/fastcommon

# fdfs编译
cd $build_p_fdfs/fastdfs
./make.sh

# fdfs 安装
./make.sh install


#检查是否安装程序正常加载所有依赖
ldd $fdfs_home/usr/bin/fdfs_trackerd
ldd $fdfs_home/usr/bin/fdfs_storaged
ldd $fdfs_home/usr/bin/fdfs_monitor

#配置服务配置文件

#etc/init.d
fift=$fdfs_home/etc/init.d/fdfs_trackerd
sed -i.bak "s#/etc/init.d/functions#$fdfs_home/etc/init.d/functions#g" $fift
sed -i     "s#PRG=/usr/bin/fdfs_trackerd#PRG=$fdfs_home/usr/bin/fdfs_trackerd#g" $fift
sed -i     "s#CONF=/etc/fdfs/tracker.conf#CONF=$fdfs_home/etc/fdfs/tracker.conf#g" $fift
fifs=$fdfs_home/etc/init.d/fdfs_storaged
sed -i.bak "s#/etc/init.d/functions#$fdfs_home/etc/init.d/functions#g" $fifs
sed -i     "s#PRG=/usr/bin/fdfs_storaged#PRG=$fdfs_home/usr/bin/fdfs_storaged#g" $fifs
sed -i     "s#CONF=/etc/fdfs/storage.conf#CONF=$fdfs_home/etc/fdfs/storage.conf#g" $fifs

#etc/fdfs
cp -f "$build_p_fdfs/fastdfs/conf/*" "$fdfs_home/etc/fdfs/"
conf=""
for conf in "`ls $build_p_fdfs/fastdfs/conf/*.conf`"; do
  n_conf=`basename $conf`
  cp -f "$conf" "$fdfs_home/etc/fdfs/${n_conf}.sample"
done


# fts_ip，tracker_server应使用真实IP地址替换
# tracker: "127.0.0.1:22122" is invalid, tracker server ip can't be 127.0.0.1
#===============================================================================
#配置主机名与ip映射，需以root权限执行：
ipaddrall=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
my_ip=$(echo ${ipaddrall} | awk '{print $1}')

HOSTNAME=`hostname`

# 以下需以root权限执行：
if [ `grep -c "$HOSTNAME" /etc/hosts` -eq '0' ]; then
  cat>>/etc/hosts<<EOF

127.0.0.1   ${HOSTNAME} ${HOSTNAME}.localdomain ${HOSTNAME}4 ${HOSTNAME}4.localdomain4
EOF
fi

if [ `grep -c "$my_ip" /etc/hosts` -eq '0' ]; then
  cat>>/etc/hosts<<EOF
$my_ip   ${HOSTNAME} ${HOSTNAME}.localdomain ${HOSTNAME}4 ${HOSTNAME}4.localdomain4
EOF
fi
#===============================================================================
fts_ip=$my_ip
fts_port=22122
fts_http_port=18080
fst_port=2300
fst_http_port=8888
fst_d0=$fdfs_home/storage/data0
fst_d1=$fdfs_home/storage/data1

mkdir -p $fdfs_home/{tracker,storage/data0}

fetr=$fdfs_home/etc/fdfs/tracker.conf
sed -i "s#^base_path=/home/yuqing/fastdfs#base_path=$fdfs_home/tracker#g" $fetr
sed -i "s#^http.server_port=8080#http.server_port=${fts_http_port}#g" $fetr
sed -i "s#^port=22122#port=${fts_port}#g" $fetr

fest=$fdfs_home/etc/fdfs/storage.conf
sed -i "s#^base_path=/home/yuqing/fastdfs#base_path=$fdfs_home/storage#g" $fest
sed -i "s#^store_path0=/home/yuqing/fastdfs#store_path0=${fst_d0}#g" $fest
sed -i "s#store_path1=/home/yuqing/fastdfs2#store_path1=${fst_d1}#g" $fest
sed -i "s#^tracker_server=192.168.209.121:22122#tracker_server=${fts_ip}:${fts_port}#g" $fest
sed -i "s#^http.server_port=8888#http.server_port=${fst_http_port}#g" $fest
sed -i "s#^port=23000#port=${fst_port}#g" $fest

# festi=$fdfs_home/etc/fdfs/storage_ids.conf
# sed -i "s###g" $festi

feht=$fdfs_home/etc/fdfs/http.conf
sed -i "s#^http.anti_steal.token_check_fail=/home/yuqing/fastdfs/conf/anti-steal.jpg#http.anti_steal.token_check_fail=$fdfs_home/etc/fdfs/anti-steal.jpg#g" $feht

fecl=$fdfs_home/etc/fdfs/client.conf
sed -i "s#^base_path=/home/yuqing/fastdfs#base_path=$fdfs_home/storage#g" $fecl
sed -i "s#^tracker_server=192.168.0.197:22122#tracker_server=${fts_ip}:${fts_port}#g" $fecl
sed -i "s#^http.tracker_server_port=80#http.tracker_server_port=${fts_http_port}#g" $fecl

###########################################################
# 启停命令
###########################################################
# 将fastdfs路径及非默认LD_LIBRARY_PATH添加到环境变量
# $fdfs_home/usr/bin → ~/.bash_profile
if [ `grep -c "# FastDFS" ~/.bash_profile` -eq '0' ]; then
  cat>>~/.bash_profile<<EOF

# FastDFS for MST system
fdfs_home=$fdfs_home
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$fdfs_home/usr/lib:\$fdfs_home/usr/lib64
export PATH=\$PATH:\$fdfs_home/bin

EOF
fi
. ~/.bash_profile
###########################################################

# $fdfs_home/etc/init.d/fdfs_trackerd start|stop|restart
# $fdfs_home/etc/init.d/fdfs_storaged start|stop|restart

mkdir -p $fdfs_home/bin/
cp $fdfs_home/etc/init.d/fdfs_trackerd $fdfs_home/bin/
cp $fdfs_home/etc/init.d/fdfs_storaged $fdfs_home/bin/

## cd $fdfs_home/bin
## ./fdfs_trackerd start|stop|restart
## ./fdfs_storaged start|stop|restart

###########################################################
# 配置文件目录$fdfs_home/etc/fdfs/中：
# tracker.conf #tracker服务依赖的配置
# storage_ids.conf #tracker服务依赖的配置
# storage.conf #storage服务依赖的配置
# http.conf #nginx模块依赖的配置
# mime.types #nginx模块依赖的配置
# mod_fastdfs.conf #nginx模块依赖的配置
# client.conf #测试客户依赖的配置

# 至此 fastdfs+libfastcommon 全部安装配置完成. 2019-08-25 PM 2:16
}

# 已经完成，临时注释：
#_build_fdfs_
######### build_fdfs 过程结束 #############################
echo -e "\n\e[34m######### build_fdfs 过程结束 #############################\e[0m\n"



###########################################################
# nginx 执行编译安装代码块： function _build_nginx_       #
###########################################################

# 为便于使用，每个nginx版本$ngxver规划3个nginx编译
# ① _build_nginx_fdfs_in_ 安装于 nginx_home=$fdfs_home/nginx-$ngxver
# ② _build_nginx_fdfs_    安装于 nginx_home=$dest_path/nginx/nginx-fdfs-$ngxver
# ③ _build_nginx_         安装于 nginx_home=$dest_path/nginx/nginx-$ngxver

###########################################################
# nginx 执行编译安装
###########################################################

export ngxver=1.17.3
###########################################################

function _build_nginx_prepare_()
{
# build_p_ngx 编译工作目录
# ngx_home    编译后安装目录

build_p_ngx=$build_p_ngx
ngx_home=$1

tar -zxf $build_src/nginx-$ngxver.tar.gz  -C $build_p_ngx

tar -zxf $build_src/openssl-1.1.1c.tar.gz  -C $build_p_ngx
unzip -o $build_src/pcre-8.43.zip  -d $build_p_ngx
tar -zxf $build_src/zlib-1.2.11.tar.gz  -C $build_p_ngx
tar -zxf $build_src/libtool-2.4.6.tar.gz  -C $build_p_ngx

cd $build_p_ngx/nginx-$ngxver

}

function _build_nginx_fdfs_prepare_()
{
# build_p_ngx 编译工作目录
# fdfs_home   编译及运行依赖目录
# ngx_home    编译后安装目录

build_p_ngx=$build_p_ngx
fdfs_home=$fdfs_home

tar -zxf $build_src/fastdfs-nginx-module-1.20.tar.gz  -C $build_p_ngx

# 修改 $build_p_ngx/fastdfs-nginx-module/src/config
fnmc=$build_p_ngx/fastdfs-nginx-module/src/config
if [ ! -f $fnmc ]; then cp $fnmc $fnmc-bak; fi
sed -i.bak "s#/usr/local/include#$fdfs_home/usr/include#g" $fnmc
sed -i     "s#/etc/fdfs/mod_fastdfs.conf#$fdfs_home/etc/fdfs/mod_fastdfs.conf#g" $fnmc

# 配置fastdfs-nginx-module配置文件到$fdfs_home/etc
fnms=$build_p_ngx/fastdfs-nginx-module/src/mod_fastdfs.conf
cp -f $fnms $fdfs_home/etc/fdfs/mod_fastdfs.conf.sample
cp -f $fnms $fdfs_home/etc/fdfs/mod_fastdfs.conf

sed -i.bak "s#^base_path=/tmp#base_path=/tmp#g" $fnms
sed -i     "s#^tracker_server=tracker:22122#tracker_server=${fts_ip}:${fts_port}#g" $fnms
sed -i     "s#^storage_server_port=23000#storage_server_port=${fst_port}#g" $fnms
sed -i     "s#^store_path0=/home/yuqing/fastdfs#store_path0=${fst_d0}#g" $fnms
sed -i     "s#store_path1=/home/yuqing/fastdfs1#store_path1=${fst_d1}#g" $fnms
sed -i     "s#log_filename=#log_filename=$fdfs_home/nginx-fdfs/logs/fdfs.log#g" $fnms

export DESTDIR=""
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${fdfs_home}/usr/lib/:${fdfs_home}/usr/lib64/"
}

function _build_nginx_after_()
{
  sed -i '/gzip  on;/a #    include ext/nginx_mst_http.conf;' $ngx_home/conf/nginx.conf
  sed -i.bak "s/ 80;/ 10080;/g" $ngx_home/conf/nginx.conf

  # 检查nginx是否正常加载所有依赖
  echo -e "\n\e[34m ngx_home=$ngx_home \e[0m\n"
  ldd $ngx_home/sbin/nginx
}

###########################################################
# nginx 执行编译安装
# 后续 nginx-fdfs 使用需要先定义 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mst_fdfs/usr/lib:$mst_fdfs/usr/lib64

###########################################################
# 编译安装 nginx
###########################################################

function _build_nginx_fdfs_in_()
{
  ngx_home=$fdfs_home/nginx && mkdir -p $ngx_home
  export ngx_home
  _build_nginx_prepare_ $ngx_home
  _build_nginx_fdfs_prepare_

  # nginx with fdfs
  ./configure \
  --prefix=$ngx_home \
  --add-module=../fastdfs-nginx-module/src \
  --with-ld-opt="-L $fdfs_home/usr/lib -Wl,-rpath=$fdfs_home/usr/lib64" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-stream \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-pcre=../pcre-8.43 \
  --with-zlib=../zlib-1.2.11 \
  --with-openssl=../openssl-1.1.1c

  make
  make install
  _build_nginx_after_
}

function _build_nginx_fdfs_()
{
  ngx_home=$dest_path/nginx/nginx-fdfs-$ngxver && mkdir -p $ngx_home
  export ngx_home
  _build_nginx_prepare_ $ngx_home
  _build_nginx_fdfs_prepare_

  # nginx with fdfs
  ./configure \
  --prefix=$ngx_home \
  --add-module=../fastdfs-nginx-module/src \
  --with-ld-opt="-L $fdfs_home/usr/lib -Wl,-rpath=$fdfs_home/usr/lib64" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-stream \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-pcre=../pcre-8.43 \
  --with-zlib=../zlib-1.2.11 \
  --with-openssl=../openssl-1.1.1c

  make
  make install
  _build_nginx_after_
}

function _build_nginx_()
{
  ngx_home=$dest_path/nginx/nginx-$ngxver && mkdir -p $ngx_home
  export ngx_home
  _build_nginx_prepare_ $ngx_home

  # nginx without fdfs
  ./configure \
  --prefix=$ngx_home \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-stream \
  --with-http_stub_status_module \
  --with-http_realip_module
  make
  make install
  _build_nginx_after_
}

_build_nginx_fdfs_in_
_build_nginx_fdfs_
_build_nginx_

#不管做了什么关于library的变动后，最好都 ldconfig 一下，不然会出现一些意想不到的结果
ldconfig

###########################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 验证安装的nginx
#  $ /srv/mstsrv/fastdfs/nginx-fdfs/sbin/nginx -t
#  nginx: the configuration file /srv/mstsrv/fastdfs/nginx-fdfs/conf/nginx.conf syntax is ok
#  nginx: [emerg] bind() to 0.0.0.0:80 failed (13: Permission denied)
#  nginx: configuration file /srv/mstsrv/fastdfs/nginx-fdfs/conf/nginx.conf test failed
# 原因：Linux只有root用户可以使用1024以下的端口。处理以root启动，或修改端口到1024以上，如改为10080。
# su root -c "$fdfs_home/nginx-fdfs/sbin/nginx -t"
# sed -i.bak "s%listen       80;%listen       10080;%g" $fdfs_home/nginx-fdfs/conf/nginx.conf

# 需已经安装包policycoreutils-python
# 查看下http允许访问的端口：
# semanage port -l | grep http_port_t
# http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
# pegasus_http_port_t            tcp      5988
# 然后我们将需要使用的端口80加入到端口列表中：
# semanage port -a -t http_port_t -p tcp 80
# semanage port -l | grep http_port_t

###########################################################
# 下一步研究 fastdfs+libfastcommon+fastdht+Berkeley DB 实现对重复上传的文件进行去重功能
# 参考 https://blog.csdn.net/Soinice/article/details/93278797
# 之前 fastdfs+libfastcommon已经下载，下边仅下载 fastdht+Berkeley DB

###########################################################

###########################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###########################################################
# 集中配置用户环境变量，后续应添加到系统运行脚本中        #
###########################################################
_conf_env_(){

# 将fastdfs路径及非默认LD_LIBRARY_PATH添加到环境变量
# $fdfs_home/usr/bin → ~/.bash_profile
if [ `grep -c "# FastDFS" ~/.bash_profile` -eq '0' ]; then
  cat>>~/.bash_profile<<EOF

# FastDFS for MST system
export fdfs_home=$fdfs_home
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$fdfs_home/usr/lib:\$fdfs_home/usr/lib64
export PATH=\$PATH:\$fdfs_home/bin

EOF
fi

# 将nginx路径环境变量
# $fdfs_home/usr/bin → ~/.bash_profile
if [ `grep -c "# Nginx" ~/.bash_profile` -eq '0' ]; then
  cat>>~/.bash_profile<<EOF

# Nginx for MST system
export ngx_home=$nxg_home
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$fdfs_home/usr/lib:\$fdfs_home/usr/lib64
export PATH=\$PATH:\$ngx_home/sbin
export

EOF
fi


. ~/.bash_profile

}
###########################################################
