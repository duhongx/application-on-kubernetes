step1:将nodejs代码编译后，然后拷贝到target/目录下

step2:构建nodejs代码的镜像
```bash
docker build -t 192.168.131.223/k8s/k8s/manager-web .
docker push 192.168.131.223/k8s/manager-web
```

step3:创建nodejs的deployment
```bash
kubectl create -f deployment.yaml
```

step4:创建nodejs的service
```bash
kubectl create -f service.yaml
```
