## ceph与kubernetes的集成

+ ceph jewel集群部署完成后，kubernetes需要使用ceph的rbd来创建storageclass，因此需要将ceph与kubernetes集成。

## 在ceph上的配置
+ 创建一个pool
```bash
ceph osd lspools
ceph osd pool create k8s 128
```
+  Ceph 存储集群默认是开启了cephx认证的，查看当前ceph集群的auth信息
```bash
[root@ceph-1 ~]# ceph auth list
installed auth entries:

osd.0
	key: AQB2E89apyzpFxAAVQVzuIXi8tGC2OiX/knx6g==
	caps: [mon] allow profile osd
	caps: [osd] allow *
osd.1
	key: AQAEFc9a1/lDIhAA8BngdqCeRRHwNIaFT9kauw==
	caps: [mon] allow profile osd
	caps: [osd] allow *
osd.2
	key: AQAFF89a8s/xMhAAT1b7nVBDfphrE5xLhgGDsw==
	caps: [mon] allow profile osd
	caps: [osd] allow *
client.admin
	key: AQBeDs9ateoyMhAAEBm9r3DuQw3gfv4KAjlYYA==
	caps: [mds] allow *
	caps: [mgr] allow *
	caps: [mon] allow *
	caps: [osd] allow *
client.bootstrap-mds
	key: AQBhDs9akzn+DBAAQzbYufKgTsL6wHKSLY0CBQ==
	caps: [mon] allow profile bootstrap-mds
client.bootstrap-mgr
	key: AQBrDs9ap9FTJRAAmEWs/V1wsLszTGGOK/hLow==
	caps: [mon] allow profile bootstrap-mgr
client.bootstrap-osd
	key: AQBmDs9aZbzEExAASWcMcB95N16vJUDtzmzcZA==
	caps: [mon] allow profile bootstrap-osd
client.bootstrap-rgw
	key: AQBvDs9aa0eQIBAALA9vbeuUuCOBq/NSdachtw==
	caps: [mon] allow profile bootstrap-rgw
client.k8s
	key: AQD/T9Ba9wYsABAAFNbi+8QGOKnbNdadfBLCnQ==
	caps: [mon] allow r
	caps: [osd] allow rwx pool=k8s
```
+ 我们选择client.admin作为kubernetes来访问ceph的用户，获取client.admin的key
```bash
[root@ceph-1 cluster]# ceph auth get-key client.admin | base64
QVFCZURzOWF0ZW95TWhBQUVCbTlyM0R1UXczZ2Z2NEtBamxZWUE9PQ==
```

## 在kubernetes上的配置

+ 需要在kubernetes的node节点上安装ceph的命令工具
```bash
yum install -y ceph-common
```

+ 需要在kubernetes上新建secret文件，存储ceph的key
```bash
[root@localhost ~]# more ceph-secret.yaml 
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
  namespace: default
type: kubernetes.io/rbd
data:
  key: QVFEL1Q5QmE5d1lzQUJBQUZOYmkrOFFHT0tuYk5kYWRmQkxDblE9PQ==
  
kubectl create -f ceph-secret.yaml 
```

+ 需要在kubernetes上创建storageclass
```bash
#备注：创建的storageclass为default，后续pod或者statefulset需要使用存储数据时只需指定容量即可，不需要指定storageclass的name，比较方便。
[root@localhost ~]# more storege.yaml 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: default
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  labels:
    kubernetes.io/cluster-service: "true"
provisioner: kubernetes.io/rbd
parameters:
    monitors: 192.168.2.105:6789,192.168.2.106:6789,192.168.2.107:6789
    adminId: admin
    adminSecretName: ceph-secret
    adminSecretNamespace: kube-system
    pool: k8s
    userId: admin
    userSecretName: ceph-secret
    fsType: ext4
    imageFormat: "1"

kubectl create -f storage.yaml
```
storage.yaml里的参数简单的解释一下
其中有几个字段要说明一下：
```bash
provisioner: 该字段指定使用存储卷类型为 kubernetes.io/rbd，注意 kubernetes.io/ 开头为 k8s 内部支持的存储提供者，不同的存储卷提供者类型这里要修改成对应的值。
adminId | userId: 这里需要指定两种 Ceph 角色 admin 和其他 user，admin 角色默认已经有了，其他 user 可以去 Ceph 集群创建一个并赋对应权限值，如果不创建，也可以都指定为 admin。
adminSecretName: 为上边创建的 Ceph 管理员 admin 使用的 ceph-secret-admin。secret中必须要有“kubernetes.io/rbd”这个type。
adminSecretNamespace 管理员 secret 使用的命名空间，默认 default。
imageFormat: Ceph RBD image format, “1” or “2”. Default is “1”. 
经过查看ceph文档rbd 块镜像有支持两种格式： –image-format format-id,format-id取值为1或2，默认为 2。 
– format 1 - 新建 rbd 映像时使用最初的格式。此格式兼容所有版本的 librbd 和内核模块，但是不支持较新的功能，像克隆。 
– format 2 - 使用第二版 rbd 格式， librbd 和 3.11 版以上内核模块才支持（除非是分拆的模块）。此格式增加了克隆支持，使得扩展更容易，还允许以后增加新功能。
imageFeatures: This parameter is optional and should only be used if you set imageFormat to “2”. Currently supported features are layering only. Default is “”, and no features are turned on.
我的ceph和rbd版本是10.2.10，不支持--image-feature，所以必须将imageFormat设为1，并且不设置imageFeatures参数。
```
