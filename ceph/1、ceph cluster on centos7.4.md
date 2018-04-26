#  Ceph jewel on centos 7.4安装部署

## 部署环境
+ Ceph.Mon = 2n+1 个 ，3个的情况下只能掉线一个，如果同时2个掉线，集群会出现无法仲裁，集群会一直等待 Ceph.Mon 恢复超过半数。本次部署选择3个节点，节点的规划如下

ceph-1  192.168.2.105  deploy/mon*1/osd*1
ceph-2  192.168.5.106  mon*1/osd*1
ceph-3  192.168.5.107  mon*1/osd*1


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
管理节点 安装 ceph-deploy 管理工具
配置 官方 的 Ceph 源
rpm --import https://download.ceph.com/keys/release.asc
rpm -Uvh --replacepkgs https://download.ceph.com/rpm-jewel/el7/noarch/ceph-release-1-0.el7.noarch.rpm
安装 epel 源
rpm -Uvh http://mirrors.ustc.edu.cn/centos/7/extras/x86_64/Packages/epel-release-7-9.noarch.rpm
[root@k8s-node1 ~]# yum makecache
[root@k8s-node1 ~]# yum -y install ceph-deploy

## 创建 Ceph-Mon
创建集群目录，用于存放配置文件，证书等信息
```bash
[root@k8s-node1 ~]# mkdir -p /opt/ceph-cluster
[root@k8s-node1 ~]# cd /opt/ceph-cluster/
```
创建ceph-mon 节点
```bash
[root@k8s-node1 /opt/ceph-cluster]# ceph-deploy new k8s-node1 k8s-node2 k8s-node3
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (1.5.39): /usr/bin/ceph-deploy new k8s-node1 k8s-node2 k8s-node3
[ceph_deploy.cli][INFO  ] ceph-deploy options:
[ceph_deploy.cli][INFO  ]  username                      : None
[ceph_deploy.cli][INFO  ]  func                          : <function new at 0xf82848>
[ceph_deploy.cli][INFO  ]  verbose                       : False
[ceph_deploy.cli][INFO  ]  overwrite_conf                : False
[ceph_deploy.cli][INFO  ]  quiet                         : False
[ceph_deploy.cli][INFO  ]  cd_conf                       : <ceph_deploy.conf.cephdeploy.Conf instance at 0xfa4a28>
[ceph_deploy.cli][INFO  ]  cluster                       : ceph
[ceph_deploy.cli][INFO  ]  ssh_copykey                   : True
[ceph_deploy.cli][INFO  ]  mon                           : ['k8s-node1', 'k8s-node2', 'k8s-node3']
[ceph_deploy.cli][INFO  ]  public_network                : None
[ceph_deploy.cli][INFO  ]  ceph_conf                     : None
[ceph_deploy.cli][INFO  ]  cluster_network               : None
[ceph_deploy.cli][INFO  ]  default_release               : False
[ceph_deploy.cli][INFO  ]  fsid                          : None
[ceph_deploy.new][DEBUG ] Creating new cluster named ceph
[ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
[k8s-node1][DEBUG ] connected to host: k8s-node1 
[k8s-node1][DEBUG ] detect platform information from remote host
[k8s-node1][DEBUG ] detect machine type
[k8s-node1][DEBUG ] find the location of an executable
[k8s-node1][INFO  ] Running command: /usr/sbin/ip link show
[k8s-node1][INFO  ] Running command: /usr/sbin/ip addr show
[k8s-node1][DEBUG ] IP addresses found: [u'172.30.89.1', u'172.30.89.0', u'192.168.5.106']
[ceph_deploy.new][DEBUG ] Resolving host k8s-node1
[ceph_deploy.new][DEBUG ] Monitor k8s-node1 at 192.168.5.106
[ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
[k8s-node2][DEBUG ] connected to host: k8s-node1 
[k8s-node2][INFO  ] Running command: ssh -CT -o BatchMode=yes k8s-node2
[k8s-node2][DEBUG ] connected to host: k8s-node2 
[k8s-node2][DEBUG ] detect platform information from remote host
[k8s-node2][DEBUG ] detect machine type
[k8s-node2][DEBUG ] find the location of an executable
[k8s-node2][INFO  ] Running command: /usr/sbin/ip link show
[k8s-node2][INFO  ] Running command: /usr/sbin/ip addr show
[k8s-node2][DEBUG ] IP addresses found: [u'192.168.5.107', u'172.30.92.1', u'172.30.92.0']
[ceph_deploy.new][DEBUG ] Resolving host k8s-node2
[ceph_deploy.new][DEBUG ] Monitor k8s-node2 at 192.168.5.107
[ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
[k8s-node3][DEBUG ] connected to host: k8s-node1 
[k8s-node3][INFO  ] Running command: ssh -CT -o BatchMode=yes k8s-node3
[k8s-node3][DEBUG ] connected to host: k8s-node3 
[k8s-node3][DEBUG ] detect platform information from remote host
[k8s-node3][DEBUG ] detect machine type
[k8s-node3][DEBUG ] find the location of an executable
[k8s-node3][INFO  ] Running command: /usr/sbin/ip link show
[k8s-node3][INFO  ] Running command: /usr/sbin/ip addr show
[k8s-node3][DEBUG ] IP addresses found: [u'172.30.62.0', u'172.30.62.1', u'192.168.5.108']
[ceph_deploy.new][DEBUG ] Resolving host k8s-node3
[ceph_deploy.new][DEBUG ] Monitor k8s-node3 at 192.168.5.108
[ceph_deploy.new][DEBUG ] Monitor initial members are ['k8s-node1', 'k8s-node2', 'k8s-node3']
[ceph_deploy.new][DEBUG ] Monitor addrs are ['192.168.5.106', '192.168.5.107', '192.168.5.108']
[ceph_deploy.new][DEBUG ] Creating a random mon key...
[ceph_deploy.new][DEBUG ] Writing monitor keyring to ceph.mon.keyring...
[ceph_deploy.new][DEBUG ] Writing initial config to ceph.conf...
```
查看配置文件
```bash
[root@k8s-node1 /opt/ceph-cluster]# more ceph.conf 
[global]
fsid = 8d0bed2b-5ec0-4b68-b145-1fcecc31cd69
mon_initial_members = k8s-node1, k8s-node2, k8s-node3
mon_host = 192.168.5.106,192.168.5.107,192.168.5.108
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
```
修改 osd 的副本数，既数据保存N份。
```bash
[root@k8s-node1 /opt/ceph-cluster]# echo 'osd_pool_default_size = 2' >> ./ceph.conf
```
注: 如果文件系统为 ext4 请添加
```bash
[root@k8s-node1 /opt/ceph-cluster]# echo 'osd max object name len = 256' >> ./ceph.conf
[root@k8s-node1 /opt/ceph-cluster]# echo 'osd max object namespace len = 64' >> ./ceph.conf
```

## 安装 Ceph
```bash
[root@k8s-node1 /opt/ceph-cluster]# ceph-deploy install k8s-node1 k8s-node2 k8s-node3 k8s-node4 k8s-node5
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (1.5.39): /usr/bin/ceph-deploy install k8s-node1 k8s-node2 k8s-node3 k8s-node4 k8s-node5
[ceph_deploy.cli][INFO  ] ceph-deploy options:
---------------------------------------
[k8s-node5][DEBUG ] Dependency Updated:
[k8s-node5][DEBUG ]   cryptsetup-libs.x86_64 0:1.7.4-3.el7_4.1                                      
[k8s-node5][DEBUG ]   device-mapper.x86_64 7:1.02.140-8.el7                                         
[k8s-node5][DEBUG ]   device-mapper-libs.x86_64 7:1.02.140-8.el7                                    
[k8s-node5][DEBUG ]   selinux-policy.noarch 0:3.13.1-166.el7_4.7                                    
[k8s-node5][DEBUG ]   selinux-policy-targeted.noarch 0:3.13.1-166.el7_4.7                           
[k8s-node5][DEBUG ] 
[k8s-node5][DEBUG ] Complete!
[k8s-node5][INFO  ] Running command: ceph --version
[k8s-node5][DEBUG ] ceph version 10.2.10 (5dc1e4c05cb68dbf62ae6fce3f0700e4654fdbbe)
```
检测安装
```bash
[root@k8s-node1 /opt/ceph-cluster]# ceph --version
ceph version 10.2.10 (5dc1e4c05cb68dbf62ae6fce3f0700e4654fdbbe)
```

## 初始化 ceph-mon 节点
```bash
[root@k8s-node1 /opt/ceph-cluster]# ceph-deploy mon create-initial
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (1.5.39): /usr/bin/ceph-deploy mon create-initial
[ceph_deploy.cli][INFO  ] ceph-deploy options:
[ceph_deploy.cli][INFO  ]  username                      : None
[ceph_deploy.cli][INFO  ]  verbose                       : False
[ceph_deploy.cli][INFO  ]  overwrite_conf                : False
[ceph_deploy.cli][INFO  ]  subcommand                    : create-initial
[ceph_deploy.cli][INFO  ]  quiet                         : False
[ceph_deploy.cli][INFO  ]  cd_conf                       : <ceph_deploy.conf.cephdeploy.Conf instance at 0xa2c7a0>
[ceph_deploy.cli][INFO  ]  cluster                       : ceph
[ceph_deploy.cli][INFO  ]  func                          : <function mon at 0xa1c8c0>
[ceph_deploy.cli][INFO  ]  ceph_conf                     : None
[ceph_deploy.cli][INFO  ]  default_release               : False
[ceph_deploy.cli][INFO  ]  keyrings                      : None
[ceph_deploy.mon][DEBUG ] Deploying mon, cluster ceph hosts k8s-node1 k8s-node2 k8s-node3
[ceph_deploy.mon][DEBUG ] detecting platform for host k8s-node1 ...
-----------------------------------------------
[k8s-node1][DEBUG ] fetch remote file
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --admin-daemon=/var/run/ceph/ceph-mon.k8s-node1.asok mon_status
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get client.admin
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get client.bootstrap-mds
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get client.bootstrap-mgr
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get-or-create client.bootstrap-mgr mon allow profile bootstrap-mgr
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get client.bootstrap-osd
[k8s-node1][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-k8s-node1/keyring auth get client.bootstrap-rgw
[ceph_deploy.gatherkeys][INFO  ] Storing ceph.client.admin.keyring
[ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-mds.keyring
[ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-mgr.keyring
[ceph_deploy.gatherkeys][INFO  ] keyring 'ceph.mon.keyring' already exists
[ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-osd.keyring
[ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-rgw.keyring
[ceph_deploy.gatherkeys][INFO  ] Destroy temp directory /tmp/tmpwXQ5nH
```

## 初始化 ceph.osd 节点
首先创建 存储空间, 如果使用分区，可略过
此次创建ceph集群的时候是每个节点都插入一块20G的/dev/vdb1，mkfs.ext4格式化后挂载到/ceph目录上，需要去osd节点上执行如下命令
chown ceph:ceph /ceph
启动 osd
```bash
[root@k8s-node1 /opt/ceph-cluster]# ceph-deploy osd prepare k8s-node2:/ceph k8s-node3:/ceph k8s-node4:/ceph k8s-node5:/ceph
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
但是测试过程中, 在使用rbd 映射块设备时, 出现一个错误, 如下 : 

[root@localhost ~]# rbd map img1 --pool pool1 -m 172.17.0.2 -k /etc/ceph/ceph.client.admin.keyring 
modinfo: ERROR: Module rbd not found.
modprobe: FATAL: Module rbd not found.
rbd: failed to load rbd kernel module (1)
rbd: sysfs write failed
rbd: map failed: (2) No such file or directory



