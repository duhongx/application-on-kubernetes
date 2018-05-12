step1:将编译好的应用拷贝到当前目录

step2:基于java:8应用做一个应用的镜像
```bash
docker build -t 192.168.131.223/k8s/manager-qgsp .
docker push 192.168.131.223/k8s/manager-qgsp
```

step3:创建java应用的deployment
```bash
kubectl create -f deployment.yaml
```

step4:创建java应用的service
```bash
kubectl create -f service.yaml
```
