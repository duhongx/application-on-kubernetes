#  Ceph 安装部署
+ 由于这里我们使用 RBD 所以我们使用到的组件为 Ceph.mon, Ceph.osd, 这两个组件就可以了。 Ceph.mds 为 cephfs 所需组件

## 部署环境
+ Ceph.Mon = 2n+1 个 ，3个的情况下只能掉线一个，如果同时2个掉线
+ 集群会出现无法仲裁，集群会一直等待 Ceph.Mon 恢复超过半数。

192.168.2.105  Ceph.admin + Ceph.Mon
192.168.5.106  Ceph.Mon + Ceph.osd
192.168.5.107  Ceph.Mon + Ceph.osd
192.168.5.110  Ceph.osd
192.168.5.111  Ceph.osd

## 初始化环境
1. ceph 对时间要求很严格， 一定要同步所有的服务器时间
开启5台机器上的ntpd服务，并设置开机启动，命令省略
2. 配置 hostname和host文件
设置5台机器的hostname
配置/etc/hosts
```bash
192.168.5.106  k8s-node1
192.168.5.107  k8s-node2
192.168.5.108  k8s-node3
192.168.5.110  k8s-node4
192.168.5.111  k8s-node5
```
3. Ceph.admin 节点 配置无密码ssh
ssh-keygen
ssh-copy-id -i /root/.ssh/id_rsa.pub root@k8s-node2
ssh-copy-id -i /root/.ssh/id_rsa.pub root@k8s-node3
ssh-copy-id -i /root/.ssh/id_rsa.pub root@k8s-node4
ssh-copy-id -i /root/.ssh/id_rsa.pub root@k8s-node5

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



