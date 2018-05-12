Step1:基于node:8官方镜像修改时区并上传到本地harbor仓库
```bash
docker build -t 192.168.131.223/k8s/node:8 .
docker push 192.168.131.223/k8s/node:8
```
