#  Ceph jewel on centos 7.4安装部署

## 部署环境
+ Ceph.Mon = 2n+1 个 ，3个的情况下只能掉线一个，如果同时2个掉线，集群会出现无法仲裁，集群会一直等待 Ceph.Mon 恢复超过半数。本次部署选择3个节点，节点的规划如下

<table>
    <tr>
        <th rowspan="8">ceph集群机器规划</th>
        <th>主机名</th>
        <th>ip地址</th>
        <th>安装组件</th>
    </tr>
    <tr>
        <td>192.168.2.105</td>
        <td>ceph-1</td>
        <td>deploy/mon*1/osd*1</td>
    </tr>
    <tr>
        <td>192.168.2.106</td>
        <td>ceph-2</td>
        <td>mon*1/osd*1</td>
    </tr>  
    <tr>
        <td>192.168.2.107</td>
        <td>ceph-3</td>
        <td>mon*1/osd*1</td>
    </tr>
</table>


## 初始化环境
1. 三台机器的centos为最小化安装，时区为默认设置，因此需要修改时区设置
```bash
ls -al /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

2. 官方建议在所有 Ceph 节点上安装 NTP 服务（特别是 Ceph Monitor 节点），以免因时钟漂移导致故障。
因此必须开启3台机器上的ntpd服务，并设置开机启动
```bash
yum -y install ntp*
systemctl start ntpd
systemctl enable ntpd
ntpq -p
```
备注：需要注意一点，centos7上的ntpd服务设置为开机启动后，重启服务器后ntpd未成功启动，查询资料得知chronyd服务与ntpd冲突导致ntpd开机启动失败，因此需要停止chronyd服务并禁止开机启动。
```bash
systemctl stop chronyd   
systemctl disable chronyd
```

3. 禁用selinux和firewalld文件
为了避免不必要的问题，建议关闭selinux和firewalld
```bash
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

4. 配置 hostname和host
设置3台机器的hostname
```bash
hostnamectl set-hostname ceph-1
vim /etc/hosts
192.168.1.105  ceph-1
192.168.1.106  ceph-2
192.168.1.107  ceph-3
```
5. Ceph deploy节点 配置无密码ssh
```bash
ssh-keygen
ssh-copy-id -i /root/.ssh/id_rsa.pub root@ceph-1
ssh-copy-id -i /root/.ssh/id_rsa.pub root@ceph-2
ssh-copy-id -i /root/.ssh/id_rsa.pub root@ceph-3
```
完成上述准备工作后，重启三台机器，重启完成后检查ntp是否开机启动，主机名是否都已修改，selinux/firewalld是否成功关闭，ssh互信是否成功。确认无问题后开始部署ceph jewel。


## 安装 Ceph-deploy

+ yum源及ceph的安装
需要在每个主机上执行以下指令
```bash
yum clean all
rm -rf /etc/yum.repos.d/*.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sed -i '/aliyuncs/d' /etc/yum.repos.d/CentOS-Base.repo
sed -i '/aliyuncs/d' /etc/yum.repos.d/epel.repo
sed -i 's/$releasever/7/g' /etc/yum.repos.d/CentOS-Base.repo
```
+ 增加ceph的源
```bash
vim /etc/yum.repos.d/ceph.repo
[ceph]
name=ceph
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/x86_64/
gpgcheck=0
[ceph-noarch]
name=cephnoarch
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/noarch/
gpgcheck=0
```
+ 安装ceph客户端
```bash
yum makecache
yum install ceph ceph-radosgw rdate -y
```


## 开始部署ceph jewel
+ 在部署节点(ceph-1)安装ceph-deploy，下文的部署节点统一指ceph-1:
```bash
[root@ceph-1 ~]# yum -y install ceph-deploy
[root@ceph-1 ~]# ceph-deploy --version
1.5.39
[root@ceph-1 ~]# ceph -v
ceph version 10.2.10 (5dc1e4c05cb68dbf62ae6fce3f0700e4654fdbbe)
``
+ 在部署节点创建部署目录并开始部署：
```bash
[[root@ceph-1 ~]# cd
[root@ceph-1 ~]# mkdir -pv /opt/cluster
[root@ceph-1 ~]# cd /opt/cluster/
[root@ceph-1 cluster]# ceph-deploy new ceph-1 ceph-2 ceph-3
```
如果之前没有ssh-copy-id到各个节点，则需要输入一下密码，过程log如下：
```bash
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (1.5.34): /usr/bin/ceph-deploy new ceph-1 ceph-2 ceph-3
[ceph_deploy.cli][INFO  ] ceph-deploy options:
[ceph_deploy.cli][INFO  ]  username                      : None
[ceph_deploy.cli][INFO  ]  func                          : <function new at 0x7f91781f96e0>
[ceph_deploy.cli][INFO  ]  verbose                       : False
[ceph_deploy.cli][INFO  ]  overwrite_conf                : False
[ceph_deploy.cli][INFO  ]  quiet                         : False
[ceph_deploy.cli][INFO  ]  cd_conf                       : <ceph_deploy.conf.cephdeploy.Conf instance at 0x7f917755ca28>
[ceph_deploy.cli][INFO  ]  cluster                       : ceph
[ceph_deploy.cli][INFO  ]  ssh_copykey                   : True
[ceph_deploy.cli][INFO  ]  mon                           : ['ceph-1', 'ceph-2', 'ceph-3']
..
..
ceph_deploy.new][WARNIN] could not connect via SSH
[ceph_deploy.new][INFO  ] will connect again with password prompt
The authenticity of host 'ceph-2 (192.168.2.106)' can't be established.
ECDSA key fingerprint is ef:e2:3e:38:fa:47:f4:61:b7:4d:d3:24:de:d4:7a:54.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'ceph-2,192.168.2.106' (ECDSA) to the list of known hosts.
root
root@ceph-2's password: 
[ceph-2][DEBUG ] connected to host: ceph-2 
..
..
[ceph_deploy.new][DEBUG ] Resolving host ceph-3
[ceph_deploy.new][DEBUG ] Monitor ceph-3 at 192.168.2.107
[ceph_deploy.new][DEBUG ] Monitor initial members are ['ceph-1', 'ceph-2', 'ceph-3']
[ceph_deploy.new][DEBUG ] Monitor addrs are ['192.168.2.105', '192.168.2.106', '192.168.2.107']
[ceph_deploy.new][DEBUG ] Creating a random mon key...
[ceph_deploy.new][DEBUG ] Writing monitor keyring to ceph.mon.keyring...
[ceph_deploy.new][DEBUG ] Writing initial config to ceph.conf...
```
此时，目录内容如下：
```bash
[[root@ceph-1 cluster]# ls
ceph.conf  ceph-deploy-ceph.log  ceph.mon.keyring
```
根据自己的IP配置向ceph.conf中添加public_network，并稍微增大mon之间时差允许范围(默认为0.05s，现改为2s)：
```bash
[root@ceph-1 cluster]# echo public_network=192.168.2.0/24 >> ceph.conf 
[root@ceph-1 cluster]# echo mon_clock_drift_allowed = 2 >> ceph.conf 
[root@ceph-1 cluster]# cat ceph.conf 
[global]
fsid = e177bed7-0210-457f-bba0-f7e66813560e
mon_initial_members = ceph-1, ceph-2, ceph-3
mon_host = 192.168.2.105,192.168.2.106,192.168.2.107
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

public_network=192.168.2.0/24
mon_clock_drift_allowed = 2
```

开始部署monitor:
```bash
[root@ceph-1 cluster]# ceph-deploy mon create-initial
..
..若干log
[root@ceph-1 cluster]# ls
ceph.bootstrap-mds.keyring  ceph.bootstrap-rgw.keyring  ceph.conf             ceph.mon.keyring
ceph.bootstrap-osd.keyring  ceph.client.admin.keyring   ceph-deploy-ceph.log
```

查看集群状态：
```bash
[root@ceph-1 cluster]# ceph -s
    cluster e177bed7-0210-457f-bba0-f7e66813560e
      health HEALTH_ERR
            no osds
            Monitor clock skew detected
     monmap e1: 3 mons at {ceph-1=192.168.2.105:6789/0,ceph-2=192.168.2.106:6789/0,ceph-3=192.168.2.107:6789/0}
            election epoch 542, quorum 0,1,2 ceph-1,ceph-2,ceph-3
     osdmap e1: 0 osds: 0 up, 0 in
            flags sortbitwise
      pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
            0 kB used, 0 kB / 0 kB avail
                  64 creating
```

开始部署OSD:
```bash
ceph-deploy --overwrite-conf osd prepare ceph-1:/dev/sdb ceph-2:/dev/sdb ceph-3:/dev/sdb --zap-disk
ceph-deploy --overwrite-conf osd activate ceph-1:/dev/sdb1 ceph-2:/dev/sdb1 ceph-3:/dev/sdb1
```
如果不出意外的话，集群状态应该如下：
```bash
[root@ceph-1 cluster]# ceph -s
    cluster e177bed7-0210-457f-bba0-f7e66813560e
      health HEALTH_WARN
            too few PGs per OSD (21 < min 30)
     monmap e1: 3 mons at {ceph-1=192.168.2.105:6789/0,ceph-2=192.168.2.106:6789/0,ceph-3=192.168.2.107:6789/0}
            election epoch 542, quorum 0,1,2 ceph-1,ceph-2,ceph-3
     osdmap e376: 3 osds: 3 up, 3 in
            flags sortbitwise,require_jewel_osds
      pgmap v105404: 256 pgs, 2 pools, 2057 MB data, 703 objects
            273 MB used, 129 GB / 134 GB avail
                 256 active+clean

```

去除这个WARN，只需要增加rbd池的PG就好：
```bash
[root@ceph-1 cluster]# ceph osd pool set rbd pgp_num 128
set pool 0 pgp_num to 128
[root@ceph-1 cluster]# ceph -s
    cluster e177bed7-0210-457f-bba0-f7e66813560e
      health ok
     monmap e1: 3 mons at {ceph-1=192.168.2.105:6789/0,ceph-2=192.168.2.106:6789/0,ceph-3=192.168.2.107:6789/0}
            election epoch 542, quorum 0,1,2 ceph-1,ceph-2,ceph-3
     osdmap e376: 3 osds: 3 up, 3 in
            flags sortbitwise,require_jewel_osds
      pgmap v105404: 256 pgs, 2 pools, 2057 MB data, 703 objects
            308 MB used, 129 GB / 134 GB avail
                 256 active+clean
```
稍等一会，集群health就会变成ok，集群部署完毕。


+ config推送
请不要使用直接修改某个节点的/etc/ceph/ceph.conf文件的方式，而是去部署节点(此处为ceph-1:/opt/cluster/ceph.conf)目录下修改。因为节点到几十个的时候，不可能一个个去修改的，采用推送的方式快捷安全！
修改完毕后，执行如下指令，将conf文件推送至各个节点：
```bash
[root@ceph-1 cluster]# ceph-deploy --overwrite-conf config push ceph-1 ceph-2 ceph-3
```

+ mon&osd启动方式
```bash
#monitor start/stop/restart
#ceph-1为各个monitor所在节点的主机名。
systemctl start ceph-mon@ceph-1.service 
systemctl restart ceph-mon@ceph-1.service
systemctl stop ceph-mon@ceph-1.service
#OSD start/stop/restart 
#0为该节点的OSD的id，可以通过`ceph osd tree`查看
systemctl start/stop/restart ceph-osd@0.service
[root@ceph-1 cluster]# ceph osd tree
ID WEIGHT  TYPE NAME       UP/DOWN REWEIGHT PRIMARY-AFFINITY 
-1 0.13170 root default                                      
-2 0.04390     host ceph-1                                   
 0 0.04390         osd.0        up  1.00000          1.00000 
-3 0.04390     host ceph-2                                   
 1 0.04390         osd.1        up  1.00000          1.00000 
-4 0.04390     host ceph-3                                   
 2 0.04390         osd.2        up  1.00000          1.00000 
```


