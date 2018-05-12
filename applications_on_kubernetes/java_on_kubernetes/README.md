step1:基于java:8应用做一个应用的镜像
```bash
docker build -t 192.168.131.226/k8s/manager-qgsp .
docker push 192.168.131.226/k8s/manager-qgsp
```

step2:创建java应用的deployment
```bash
kubectl create -f deployment.yaml
```

step3:创建java应用的service
```bash
kubectl create -f service.yaml
```
