

## rabbitmq cluster on kubernetes 

+ 使用rabbitmq:3.6.6-management-alpine这个镜像，可以先将镜像直接拉下来，然后打个tag，推到本地的harbor仓库。
```bash
docker pull rabbitmq:3.6.6-management-alpine
docker tag 7c94740ef743 192.168.2.101/k8s/rabbitmq:3.6.6-management-alpine
docker push 192.168.2.101/k8s/rabbitmq:3.6.6-management-alpine
```

+ 直接创建rabbitmq cluster
```bash
echo $(openssl rand -base64 32) > erlang.cookie
kubectl create secret generic erlang.cookie --from-file=erlang.cookie
kubectl create -f rabbitmq.yaml
#这个部署较慢，需要耐心等待，pod需要加载一些卷，申请rbd资源，然后格式化挂载，多次查看pod创建过程中的日志和分配node的kubelet日志，来定位问题
```

+ 查看rabbitmq的pvc信息
```bash
#从rabbitmq.yaml文件中可以看到总共3个statefulset的rabbitmq，每个申请了5G的空间，创建pod的时候会自动生成pvc/pv的信息，如果有问题说明ceph和kubernetes的集成配置有问题，需要根据报错的具体信息来检查相应的配置并修改。
[root@localhost rabbitmq]# kubectl get pvc,pv | grep rabbitmq
pvc/rabbitmq-rabbitmq-0    Bound     pvc-109d4fb5-421a-11e8-9fd6-000c292195ce   5Gi        RWO            default        8d
pvc/rabbitmq-rabbitmq-1    Bound     pvc-4e95dab7-421b-11e8-b2e7-000c29359890   5Gi        RWO            default        8d
pvc/rabbitmq-rabbitmq-2    Bound     pvc-2f26199f-421d-11e8-b1c6-000c29b32c9b   5Gi        RWO            default        8d

pv/pvc-109d4fb5-421a-11e8-9fd6-000c292195ce   5Gi        RWO            Delete           Bound     default/rabbitmq-rabbitmq-0    default                  8d
pv/pvc-2f26199f-421d-11e8-b1c6-000c29b32c9b   5Gi        RWO            Delete           Bound     default/rabbitmq-rabbitmq-2    default                  8d
pv/pvc-4e95dab7-421b-11e8-b2e7-000c29359890   5Gi        RWO            Delete           Bound     default/rabbitmq-rabbitmq-1    default                  8d

```

+ 查看pod/svc信息
```bash
[root@localhost rabbitmq]# kubectl get pod,svc | grep rabbitmq
po/rabbitmq-0                  1/1       Running   0          7d
po/rabbitmq-1                  1/1       Running   0          7d
po/rabbitmq-2                  1/1       Running   0          7d

svc/rabbitmq              ClusterIP   None            <none>        5672/TCP,4369/TCP,25672/TCP   8d
svc/rabbitmq-management   NodePort    10.68.118.200   <none>        15672:30764/TCP               8d
```

+ 可以登陆rabbitmq-management的web页面来查看集群的信息
```bash
通过http://192.168.2.102:30764，用户名为guest，密码为guest
ip为任意一个node的ip地址，30764为NodePort对应的端口
```
