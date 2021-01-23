# Kubernetes快速实战

## 1 Kubernetes安装与配置

### 1.1 K8s介绍

中文社区

https://www.kubernetes.org.cn/





### 1.2 硬件安装要求

| 序号 | 硬件 | 要求    |
| ---- | ---- | ------- |
| 1    | CPU  | 至少2核 |
| 2    | 内存 | 至少3G  |
| 3    | 硬盘 | 至少50G |

临时演示集群节点

| 主机名 | 主机IP       |
| ------ | ------------ |
| master | 10.13.106.31 |
| node1  |              |
| node2  |              |
|        |              |

centos下载地址:推荐大家使用centos7.6以上版本。

```bash
http://mirrors.aliyun.com/centos/7/isos/x86_64/ 
```

设置hostname

```shell
#临时
hostname <newhostname>
#永久
vi /etc/hostname
```

查看IP地址

```bash
#第一种
ip addr
#第二种
ifconfig
```



配置阿里云yum源

```bash
#1.下载安装wget
yum install -y wget
#2.备份默认的yum
mv /etc/yum.repos.d /etc/yum.repos.d.backup
#3.设置新的yum目录
mkdir -p /etc/yum.repos.d
#4.下载阿里yum配置到该目录中，选择对应版本
# centos-7.repo文件里面有的是使用的是https://mirrors.aliyuncs.com.建议都注释掉，这个地址是用在阿里云服务器内网的，我们自己的电脑不可能链接得到，所以这个我就注释了。
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#名字改成 CentOS-Base.repo 
#sed -i 's/https/https/g' /etc/yum.repos.d/CentOS-Base.repo
#5.更新epel源为阿里云epel源
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup

wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#6.重建缓存
yum clean all
# 可能会缓存失败。。。多试几次
yum makecache
#7.看一下yum仓库有多少包
yum repolist
yum update
```

升级系统内核

```bash
# 先下载再按照elrepo-release-7.0-3.el7.elrepo.noarch.rpm 
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm 

yum --enablerepo=elrepo-kernel install -y kernel-lt
grep initrd16 /boot/grub2/grub.cfg
grub2-set-default 0

reboot
```

查看centos系统内核命令：

```bash
uname -r
uname -a
```

查看内存

```bash
free -h
```

查看CPU命令：

```bash
lscpu
```

查看硬盘信息

```bash
fdisk -l 
```

### 1.3 centos7系统配置

#### 1.3.1 关闭防火墙

```bash
systemctl stop firewalld
systemctl disable firewalld
```

#### 1.3.2 关闭selinux

```bash
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
```

#### 1.3.3 网桥过滤

```bash
vi /etc/sysctl.conf

net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.ipv4.ip_forward=1
net.ipv4.ip_forward_use_pmtu = 0

生效命令
sysctl --system
查看效果
sysctl -a|grep "ip_forward"
```

#### 1.3.4 开启IPVS

```bash
#安装IPVS
yum -y install ipset ipvsdm
#编译ipvs.modules文件
vi /etc/sysconfig/modules/ipvs.modules
#文件内容如下
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
#赋予权限并执行
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules 
lsmod | grep -e ip_vs -e nf_conntrack_ipv4
#重启电脑，检查是否生效
reboot
lsmod | grep ip_vs_rr
```

#### 1.3.5 同步时间

```bash
#安装软件
yum -y install ntpdate
#向阿里云服务器同步时间
ntpdate time1.aliyun.com
#删除本地时间并设置时区为上海
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#查看时间
date -R || date
```

#### 1.3.6 命令补全

```bash
#安装bash-completion
yum -y install bash-completion bash-completion-extras
#使用bash-completion
source /etc/profile.d/bash_completion.sh
```

#### 1.3.7 关闭swap分区

```bash
#临时关闭：
swapoff -a
#永久关闭：
vi /etc/fstab
#将文件中的/dev/mapper/centos-swap这行代码注释掉
#/dev/mapper/centos-swap swap swap  defaults    0 0
#确认swap已经关闭：若swap行都显示 0 则表示关闭成功
free -m
```

#### 1.3.8 hosts配置

```bash
vi /etc/hosts
文件内容如下:
cat <<EOF >>/etc/hosts
192.168.134.132 master
EOF

systemctl restart network 
```



### 1.3 安装docker

参考 https://www.aliyun.com/ 

- 安装docker前置条件

  ```bash
  yum install -y yum-utils device-mapper-persistent-data lvm2 
  ```

  

- 添加源

  cd /etc/yum.repos.d/

  ```bash
  #下载 http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  yum-config-manager --add-repo docker-ce.repo
  yum makecache fast
  ```

  ```shell
  vi /etc/yum.repos.d/docker-ce.repo
  通过命令把https://download-stage.docker.com替换为http://mirrors.aliyun.com/docker-ce
  sed -i 's/http/https/g' /etc/yum.repos.d/docker-ce.repo
  ```

  

- 安装docker最新版本

  ```bash
  yum -y install docker-ce
  #安装指定版本：
  yum -y install docker-ce-19.03.8
  yum install docker-ce-19.03.8 docker-ce-cli-19.03.8 containerd.io
  #可以通过docker version命令查看
  docker-client版本：当前最新版本
  docker-server版本为：19.03.8
  ```

  

- 开启dock而服务

  ```bash
  systemctl start docker
  systemctl status docker
  ```

  

- 安装阿里云镜像加速器

  ```bash
  sudo mkdir -p /etc/docker
  sudo tee /etc/docker/daemon.json <<-'EOF'
  {
    "registry-mirrors": ["https://5jp2v6ww.mirror.aliyuncs.com"],
    "exec-opts": ["native.cgroupdriver=systemd"]
  }
  EOF
  sudo systemctl daemon-reload
  
  sudo systemctl restart docker
  ```

  

- 设置docker开启启动服务

  ```bash
  systemctl enable docker
  ```

  

- 修改Cgroup Driver

  ```bash
  #修改daemon.json，新增：
  "exec-opts": ["native.cgroupdriver=systemd"]
  #重启docker服务：
  systemctl daemon-reload
  systemctl restart docker
  #查看修改后状态：
  docker info | grep Cgroup
  ```

  

- 复习docker常用命令

  ```bash
  docker -v
  docker version
  docker info
  ```

### 1.4 使用kubeadm快速安装

vi /etc/yum.repos.d/kubernates.repo

```shell
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.cloud.tencent.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.cloud.tencent.com/kubernetes/yum/doc/yum-key.gpg 
       https://mirrors.cloud.tencent.com/kubernetes/yum/doc/rpm-package-key.gpg

```

- 更新缓存

  ```bash
  yum clean all
  yum -y makecache
  ```

- 验证源是否可用

  ```bash
  yum list | grep kubeadm
  #如果提示要验证yum-key.gpg是否可用，输入y。
  #查找到kubeadm。显示版本
  ```

- 查看k8s版本

  ```bash
  yum list kubelet --showduplicates | sort -r 
  ```

  

- 安装k8s-1.17.5

  ```bash
  yum install -y kubelet-1.17.5 kubeadm-1.17.5 kubectl-1.17.5
  ```

- 设置kubelet，增加配置信息

  ```bash
  #如果不配置kubelet，可能会导致K8S集群无法启动。为实现docker使用的cgroupdriver与kubelet 使用的cgroup的一致性。
  vi /etc/sysconfig/kubelet
  KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
  ```

  设置开机启动

  ```bash
  systemctl enable kubelet 
  ```


- 查看服务状态

  ```bash
  systemctl status kubelet
  ```

  

- 查看版本信息

  ```bash
  kubelet --version
  ```

- 重启与重置

  ```bash
  # 重启服务
  systemctl restart kubelet
  # 重置
  kubeadm reset --force
  ```



### 1.5 初始化镜像

如果是第一次安装k8s，手里没有备份好的镜像，可以执行如下操作

见讲义

生成tar包下次就可以直接导入



### 1.6 k8s导入镜像

导入master节点镜像tar包

```bash
#master节点需要全部镜像
docker load -i k8sv1.17.6.tar
```

导入node节点镜像tar包

```bash
#node节点需要kube-proxy:v1.17.6和pause:3.1,2个镜像.或者也可导入全部
docker load -i k8s.1.17.6.node.tar
```



### 1.7 k8s 初始化集群

```bash
kubeadm init --apiserver-advertise-address=192.168.134.132 --kubernetes-version v1.17.5 --service-cidr=10.1.0.0/16 --pod-network-cidr=10.81.0.0/16 --ignore-preflight-errors=all --v=5

```

执行配置命令:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

```bash
#???
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/
  
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```



node节点加入集群信息:

```bash
kubeadm join 192.168.134.132:6443 --token 8dxnen.cna2a6g5lulo66vj \
    --discovery-token-ca-cert-hash sha256:ded28a82712fd26e7d7ca38ecbfbd00db21ed255c3c9ad2b1b3475a9eac83d69
```



**安装 calico网络**

```bash
#下载 https://docs.projectcalico.org/v3.14/manifests/calico.yaml
kubectl apply -f calico.yaml
```

查看节点状态

```bash
kubeadm get nodes
```

**允许master节点部署pod**

```bash
#允许master节点部署pod
kubectl taint nodes --all node-role.kubernetes.io/master-
#如果不允许调度
kubectl taint nodes master1 node-role.kubernetes.io/master=:NoSchedule
#污点可选参数
	  #NoSchedule: 一定不能被调度
      #PreferNoSchedule: 尽量不要调度
      #NoExecute: 不仅不会调度, 还会驱逐Node上已有的Pod

```

kubectl命令自动补全:

```bash
echo "source <(kubectl completion bash)" >> ~/.bash_profile
source ~/.bash_profile
```

**删除节点**

```bash
#删除节点：

#（1）卸载节点（drain 翻译排出，此时卸载节点，但是没有删除）

kubectl drain <node name> --delete-local-data --force --ignore-daemonsets

#（2）删除节点

kubectl delete node <node name>

#（3）清空init配置，需要删除的节点上执行

kubeadm reset
```



发送邮件问题:

```bash
在 bash 中设置当前 shell 的自动补全，要先安装 bash-completion 包。
echo "unset MAILCHECK">> /etc/profile
source /etc/profile
在你的 bash shell 中永久的添加自动补全
```

yum-key.gpg验证未通过:

```bash
wget https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
wget https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
rpm --import yum-key.gpg
rpm --import rpm-package-key.gpg
```



```bash
# 问题一 : CNI 网络插件自身的 Bug。具体而言我有更换过 CNI 网络插件，没多久后就 IP 溢出了
# 解决：删除掉 /var/lib/cni 中所有的 IP 地址
Warning  FailedCreatePodSandBox  2m12s                kubelet, node1     Failed to create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "cff2bad94b2e79c266f8377cfd5de8a13f22a9e8d0a0abcb4f06d85ba52fa65b" network for pod "tomcatdevelop-7cb9ccb4f5-cwcs7": networkPlugin cni failed to set up pod "tomcatdevelop-7cb9ccb4f5-cwcs7_default" network: unable to allocate IP address: Post "http://127.0.0.1:6784/ip/cff2bad94b2e79c266f8377cfd5de8a13f22a9e8d0a0abcb4f06d85ba52fa65b": dial tcp 127.0.0.1:6784: connect: connection refused, failed to clean up sandbox container "cff2bad94b2e79c266f8377cfd5de8a13f22a9e8d0a0abcb4f06d85ba52fa65b" network for pod "tomcatdevelop-7cb9ccb4f5-cwcs7": networkPlugin cni failed to teardown pod "tomcatdevelop-7cb9ccb4f5-cwcs7_default" network: Delete "http://127.0.0.1:6784/ip/cff2bad94b2e79c266f8377cfd5de8a13f22a9e8d0a0abcb4f06d85ba52fa65b": dial tcp 127.0.0.1:6784: connect: connection refused]
  Normal   SandboxChanged          2s (x11 over 2m11s)  kubelet, node1     Pod sandbox changed, it will be killed and re-created.
```



## 2, k8s快速入门之命令行

### 2.1 NameSpace

#### 2.1.1 查看命名空间

```bash
kubectl get namespace
#查看所有命名空间的pod资源
kubectl get pod --all-namespaces
kubectl get pod -A
#简写命令
kubectl get ns
```

```bash
default 用户创建的pod默认在此命名空间
kube-public 所有用户均可以访问，包括未认证用户
kube-node-lease kubernetes集群节点租约状态,v1.13加入
kube-system kubernetes集群在使用
```

#### 2.1.2 创建NameSpace

```bash
kubectl create namespace lagou
#简写命令
kubectl create ns lagou
```

#### 2.1.3 删除NameSpace

```bash
kubectl delete namespace lagou
#简写命令
kubectl delete ns lagou
```



### 2.2 Pod

Pod是kubernetes集群能够调度的最小单元。Pod是容器的封装 

在Pod中的容器可能会由于异常等原因导致其终止退出，Kubernetes提供了重启策略以重启容器。重启策略对同一个Pod的所有容器起作用，容器的重启由Node上的kubelet执行。Pod支持三种重启策略，在配置文件中通过restartPolicy字段设置重启策略：

1. Always：只要退出就会重启。
2. OnFailure：只有在失败退出（exit code不等于0）时，才会重启。
3. Never：只要退出，就不再重启

#### 2.2.1 查看Pod

```bash
#查看default命名空间下的pods
kubectl get pods
#查看kube-system命名空间下的pods
kubectl get pods -n kube-system
#查看所有命名空间下的pods
kubectl get pod --all-namespaces
kubectl get pod -A
```

#### 2.2.2 创建Pod

##### 下载镜像

```bash
#K8S集群的每一个节点都需要下载镜像:选择不同的基础镜像，下载镜像的大小也不同。
docker pull tomcat:9.0.20-jre8-alpine    108MB
docker pull tomcat:9.0.37-jdk8-openjdk-slim 305MB
docker pull tomcat:9.0.37-jdk8        531MB
#同学们可以自行下载后进行备份。
docker save -o tomcat9.tar tomcat:9.0.20-jre8-alpine
docker load -i tomcat9.tar
```

##### 运行pod

```bash
#在default命名空间中创建一个pod副本的deployment
kubectl run tomcat9-test --image=tomcat:9.0.20-jre8-alpine --port=8080

kubectl run tomcat-test --image=tomcat:9.0.37-jdk8-openjdk-slim --port=8081

kubectl get pod
kubectl get pod -o wide
#使用pod的IP访问容器
crul ***:8080
```

如果是单节点模式，需要执行

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```



#### 2.2.3 扩容

```bash
#将副本扩容至3个
kubectl scale --replicas=3 deployment/tomcat9-test
kubectl get deployment
kubectl get deployment -o wide
#使用deployment的IP访问pod
```

#### 2.2.4 创建服务

```bash
# 服务名字是 tomcat9-svc NodePort 指的是默认随机端口，就是生成的32546
kubectl expose deployment tomcat9-test --name=tomcat9-svc --port=8888 --target-port=8080 --protocol=TCP --type=NodePort
kubectl get svc
kubectl get svc -o wide

[root@master ~]# kubectl get service -o wide
NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE   SELECTOR
kubernetes    ClusterIP   10.1.0.1     <none>        443/TCP          74m   <none>
tomcat9-svc   NodePort    10.1.125.7   <none>        8888:32546/TCP   10m   run=tomcat9-test

#访问服务端口,集群内访问端口号是8888
curl 10.1.125.7:8888
#访问集群外端口,集群外访问端口号是32546
http://192.168.134.132:32546
```



### 2.3 kubectl常用命令练习

#### 2.3.1 语法规则

```bash
kubectl [command] [TYPE] [NAME] [flags] 
```

其中  command 、 TYPE 、 NAME 和  flags 分别是：

- command ：指定要对一个或多个资源执行的操作，例如  create 、 get 、 describe 、 delete 。
- TYPE ：指定资源类型。资源类型不区分大小写，可以指定单数、复数或缩写形式。例如，以下命令输出相同的结果:



#### 2.3.2 get命令

kubectl get - 列出一个或多个资源。

```bash
# 查看集群状态信息
kubectl cluster-info      
# 查看集群状态
kubectl get cs
# 查看集群节点信息
kubectl get nodes
# 查看集群命名空间
kubectl get ns             
# 查看指定命名空间的服务
kubectl get svc -n kube-system     
# 以纯文本输出格式列出所有 pod。
kubectl get pods
# 以纯文本输出格式列出所有 pod，并包含附加信息(如节点名)。
kubectl get pods -o wide
# 持续检测pod信息
kubectl get pods -w
# 以纯文本输出格式列出具有指定名称的副本控制器。提示：您可以使用别名 'rc' 缩短和替换
'replicationcontroller' 资源类型。
kubectl get replicationcontroller <rc-name>
# 以纯文本输出格式列出所有副本控制器和服务。
kubectl get rc,services
# 以纯文本输出格式列出所有守护程序集，包括未初始化的守护程序集。
kubectl get ds --include-uninitialized
# 列出在节点 server01 上运行的所有 pod
kubectl get pods --field-selector=spec.nodeName=server01 
```

#### 2.3.3 describe命令

kubectl describe - 显示一个或多个资源的详细状态，默认情况下包括未初始化的资源。

```bash
# 显示名称为 <node-name> 的节点的详细信息。
kubectl describe nodes <node-name>
# 显示名为 <pod-name> 的 pod 的详细信息。
kubectl describe pods/<pod-name>
# 显示由名为 <rc-name> 的副本控制器管理的所有 pod 的详细信息。
# 记住：副本控制器创建的任何 pod 都以复制控制器的名称为前缀。
kubectl describe pods <rc-name>
# 描述所有的 pod，不包括未初始化的 pod
kubectl describe pods --include-uninitialized=false
```

例如：

```bash
[root@master data]# kubectl describe pod tomcatdevelop-7cb9ccb4f5-h2w7d
Name:         tomcatdevelop-7cb9ccb4f5-h2w7d
Namespace:    default
Priority:     0
Node:         master/192.168.134.132
Start Time:   Thu, 21 Jan 2021 12:27:59 +0800
Labels:       app=tomcatpod
              pod-template-hash=7cb9ccb4f5
Annotations:  <none>
Status:       Running
IP:           10.32.0.3
IPs:
  IP:           10.32.0.3
Controlled By:  ReplicaSet/tomcatdevelop-7cb9ccb4f5
Containers:
  tomcatdevelop:
    Container ID:   docker://b22093970bdef5e071d0c816609d003a7b3818f4286876a717c7b9e3b181212e
    Image:          tomcat:9.0.20-jre8-alpine
    Image ID:       docker-pullable://tomcat@sha256:17accf0afeeecce0310d363490cd60a788aa4630ab9c9c802231d6fbd4bb2375
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 21 Jan 2021 12:28:11 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-splkg (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  default-token-splkg:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-splkg
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  55s   default-scheduler  Successfully assigned default/tomcatdevelop-7cb9ccb4f5-h2w7d to master
  Normal  Pulled     47s   kubelet, master    Container image "tomcat:9.0.20-jre8-alpine" already present on machine
  Normal  Created    43s   kubelet, master    Created container tomcatdevelop
  Normal  Started    42s   kubelet, master    Started container tomcatdevelop
```



#### 2.3.4 delete命令

kubectl delete` - 从文件、stdin 或指定标签选择器、名称、资源选择器或资源中删除资源。

```bash
# 删了还会再生成pod
kubectl delete pod <pod_name>
# 使用 pod.yaml 文件中指定的类型和名称删除 pod。
kubectl delete -f pod.yaml
# 删除标签名= <label-name> 的所有 pod 和服务。
kubectl delete deployments.apps <label-name>
# 删除service
kubectl delete service/<service_name>
# 删除所有具有标签名称= <label-name> 的 pod 和服务，包括未初始化的那些。
kubectl delete pods,services -l name=<label-name> --include-uninitialized
# 删除所有 pod，包括未初始化的 pod。
kubectl delete pods --all
```

#### 2.3.5 进入容器命令

kubectl exec - 对 pod 中的容器执行命令。与docker的exec命令非常类似

```bash
# 从 pod <pod-name> 中获取运行 'date' 的输出。默认情况下，输出来自第一个容器。
kubectl exec <pod-name> date
# 运行输出 'date' 获取在容器的 <container-name> 中 pod <pod-name> 的输出。
kubectl exec <pod-name> -c <container-name> date
# 获取一个交互 TTY 并运行 /bin/bash <pod-name >。默认情况下，输出来自第一个容器。
kubectl exec -ti <pod-name> /bin/bash
```

#### 2.3.6 logs命令

kubectl logs - 打印 Pod 中容器的日志。

```bash
# 从 pod 返回日志快照。
kubectl logs <pod-name>
# 从 pod <pod-name> 开始流式传输日志。这类似于 'tail -f' Linux 命令。
kubectl logs -f <pod-name>
```



#### 2.3.7 格式化输出

```bash
#将pod信息格式化输出到一个yaml文件
kubectl get pod web-pod-13je7 -o yaml
```

#### 2.3.8 强制删除pod

```bash
强制删除一个pod
--force --grace-period=0
```



## 3. k8s资源文件

### 3.1 idea安装k8s插件

- 官网地址

  ```bash
  https://plugins.jetbrains.com/
  kubernetes地址：
  https://plugins.jetbrains.com/plugin/10485-kubernetes
  ```

  

- 离线安装

  ```bash
  因国外网站网速较慢，在线安装有安装失败的危险。推荐大家下载idea对应版本的插件后，进行离线安装
  193.5662.65
  settings->plugins->Install Plugin from Disk->插件安装目录
  安装完成后重启idea开发工具
  ```



### 3.2 idea配置SSH客户端

目标：在idea中打开终端操作k8s集群master节点。



### 3.3 Remote Host



### 3.4 NameSpace

```bash
settings->Editor->Live Template->Kubernetes->查看自动生成的模板信息内容
```

生成模板快捷键:

多个资源可以用 --- 分隔开

| kres | 资源，如namespace |
| ---- | ----------------- |
| kpod | pod               |
| kser | service           |
| kdep | develop           |

- 创建namespace

  ```bash
  apiVersion: v1
  kind: Namespace
  metadata:
    name: lagou
  ```

  ```bash
  mkdir -p /data/namespaces
  cd /data/namespaces
  kubectl apply -f lagounamespace.yml
  
  # . 的意思是执行当前目录下所有的yaml
  kubectl apply -f .
  
  #创建namespace后，再操作需要加上namespace参数
  kubectl get pods --namespace=lagou
  ```

  

- 删除namespace

  ```bash
  kubectl delete -f lagounamespace.yml
  ```

  

### 3.5 pod

- 创建pod

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: tomcat9
    labels:
      app: tomcat9
    namespace: lagou
  spec:
    containers:
      - name: tomcat9
        image: tomcat:9.0.20-jre8-alpine
        imagePullPolicy: IfNotPresent
    restartPolicy: Always
  ```

- 下载策略，重启策略

  ```bash
  imagePullPolicy:
   Always:总是拉取 pull
   IfNotPresent:如果本地有镜像，使用本地，如果本地没有镜像，下载镜像。
   Never:只使用本地镜像，从不拉取
   
  restartPolicy:
   Always：只要退出就重启。
   OnFailure：失败退出时（exit code不为0）才重启
   Never：永远不重启
  ```

  

- 运行pod

  ```bash
  kubectl apply -f tomcatpod.yml
  ```

- 删除pod

  ```bash
  kubectl delete -f tomcatpod.yml 
  ```

  

### 3.6 deployment

- 创建deployment

  在idea工程resource/deployment/tomcatdeployment.yml

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: tomcatdevelop
    labels:
      app: tomcatPod
  spec:
    replicas: 1
    template:
      metadata:
        name: tomcatdevelop
        labels:
          app: tomcatPod
      spec:
        containers:
          - name: tomcatdevelop
            image: tomcat:9.0.20-jre8-alpine
            imagePullPolicy: IfNotPresent
        restartPolicy: Always
    selector:
      matchLabels:
        app: tomcatPod
  ```

- 运行deployment

  ```bash
  kubectl apply -f tomcatdeployment.yml 
  ```

- 删除Deployment

  ```bash
  kubectl delete -f tomcatdeployment.yml
  ```

  

### 3.7 service

- 创建service

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    namespace: lagou
    name: tomcatdevelop
    labels:
      app: tomcatpod
  spec:
    replicas: 1
    template:
      metadata:
        name: tomcatdevelop
        labels:
          app: tomcatpod
      spec:
        containers:
          - name: tomcatdevelop
            image: tomcat:9.0.20-jre8-alpine
            imagePullPolicy: IfNotPresent
        restartPolicy: Always
    selector:
      matchLabels:
        app: tomcatpod
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: tomcatsvc
  spec:
    selector:
      app: tomcatpod
    ports:
      - port: 8888
        targetPort: 8080
        nodePort: 30012
        protocol: TCP
    type: NodePort
  ```

  

- service的selector

  ```bash
  service.spec.selector.app选择的内容仍然是template.label.app内容。而不是我们deployment控制器的label内容
  ```

  

- Service类型

  ```bash
  ClusterIP：默认，分配一个集群内部可以访问的虚拟IP
  NodePort：在每个Node上分配一个端口作为外部访问入口
  LoadBalancer：工作在特定的Cloud Provider上，例如Google Cloud，AWS，OpenStack
  ExternalName：表示把集群外部的服务引入到集群内部中来，即实现了集群内部pod和集群外部的服务进行通信
  ```

- Service参数

  ```bashe
  port ：访问service使用的端口
  targetPort ：Pod中容器端口
  NodePort： 通过Node实现外网用户访问k8s集群内service(30000-32767) 
  ```

- 运行，删除service

  ```bash
  kubectl apply -f tomcatservice.yml 
  kubectl delete -f tomcatservice.yml 
  ```

  



# Kubernetes进阶

## 1. 资源清单pod进阶

### 1.1 1initC 初始化

initC特点：

1. initC总是运行到成功完成为止。

2. 每个initC容器都必须在下一个initC启动之前成功完成。

3. 如果initC容器运行失败，K8S集群会不断的重启该pod，直到initC容器成功为止。

4. 如果pod对应的restartPolicy为never，它就不会重新启动。

   

pod/initcpod.yml文件,需要准备busybox:1.32.0镜像:

```bash
apiVersion: v1
kind: Pod
metadata:
name: myapp-pod
labels:
 app: myapp
spec:
containers:
 - name: myapp-container
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  command: ['sh', '-c', 'echo The app is running! && sleep 3600']
initContainers:
 - name: init-myservice
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  command: ['sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done;']
 - name: init-mydb
  image: busybox:1.32.0
  command: ['sh', '-c', 'until nslookup mydb; do echo waiting for mydb;sleep 2; done;']
```

pod/initcservice1.yml:

```bash
apiVersion: v1
kind: Service
metadata:
name: myservice
spec:
ports:
 - protocol: TCP
  port: 80
  targetPort: 9376
```

pod/initcservice2.yml:

```bash
apiVersion: v1
kind: Service
metadata:
name: mydb
spec:
ports:
 - protocol: TCP
  port: 80
  targetPort: 9377
```

```bash
#查看myapp-pod运行情况，需要耐心等一会，会发现pod的两个init已经就绪，pod状态为ready
kubectl get pod -w
```



### 1.2 readinessProbe (就绪检测)

pod/readinesstest.yml:

没有通过就绪检测的服务 READY状态是0，只有通过才会变成1

```bash
apiVersion: v1
kind: Pod
metadata:
name: readinesstest
labels:
 app: readinesstest
spec:
containers:
 - name: readinesstest
  image: nginx:1.17.10-alpine
  imagePullPolicy: IfNotPresent
  readinessProbe:
   httpGet:
    port: 80
    path: /index1.html
   initialDelaySeconds: 1
   periodSeconds: 3
restartPolicy: Always
```

```bash
#创建pod
kubectl apply -f readinesstest.yml
#检查pod状态，虽然pod状态显示running但是ready显示0/1，因为就绪检查未通过
kubectl get pods
#查看pod详细信息，文件最后一行显示readiness probe failed。。。。
kubectl describe pod readinesstest
#进入pod内部，因为是alpine系统，需要使用sh命令
kubectl exec -it readinesstest sh
#进入容器内目录
cd /usr/share/nginx/html/
#追加一个index1.html文件
echo "welcome lagou" >> index1.html
#退出容器，再次查看pod状态，pod已经正常启动
exit
kubectl get pods
```

```bash
[root@master data]# kubectl get pod -o wide
NAME            READY   STATUS    RESTARTS   AGE     IP          NODE     NOMINATED NODE   READINESS GATES
readinesstest   1/1     Running   0          5m17s   10.32.0.3   master   <none>           <none>
[root@master data]# curl 10.32.0.3:80/index1.html
hello k8s!!!

```



### 1.3 livenessProbe(存活检测)

容器存活检测，需要准备busybox:1.32.0镜像

pod/livenessprobepod.yml

```bash
apiVersion: v1
kind: Pod
metadata:
name: livenessprobe-pod
labels:
 app: livenessprobe-pod
spec:
containers:
 - name: livenessprobe-pod
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  command: ["/bin/sh","-c","touch /tmp/livenesspod ; sleep 30; rm -rf /tmp/livenesspod; sleep 3600"]
  livenessProbe:
   exec:
    command: ["test","-e","/tmp/livenesspod"]
   initialDelaySeconds: 1
   periodSeconds: 3
restartPolicy: Always
```

```bash
 kubectl exec -it livenesstest --namespace=lagou -- rm -rf /usr/share/nginx/html/index.html
```



### 1.4 钩子函数案例

postStart函数,需要准备busybox:1.32.0镜像

pod/lifeclepod.yml

```bash
apiVersion: v1
kind: Pod
metadata:
name: lifecle-pod1
labels:
 app: lifecle-pod1
spec:
containers:
 - name: lifecle-pod1
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  lifecycle:
   postStart:
    exec:
    #创建/lagou/k8s/目录，在目录下创建index.html
     command: ['mkdir','-p','/lagou/k8s/index.html']
  command: ['sh','-c','sleep 5000']
restartPolicy: Always
```



## 2. ingress网络





## 3. k8s volume(存储)

### 3.1 案例准备工作

准备镜像

k8s集群每个node节点需要下载镜像：

```bash
docker pull mariadb:10.5.2 
```

安装mariaDB

部署service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadbpod
  labels:
    app: mariadbpod
spec:
  replicas: 1
  template:
    metadata:
      name: mariadbpod
      labels:
        app: mariadbpod
    spec:
      containers:
        - name: mariadbpod
          image: mariadb:10.5.2
          imagePullPolicy: IfNotPresent
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: root
            - name: TZ
              value: Asia/Shanghai
          args:
            - "--character-set-server=utf8mb4"
            - "--collation-server=utf8mb4_unicode_ci"
          ports:
            - containerPort: 3306
      restartPolicy: Always
  selector:
    matchLabels:
      app: mariadbpod

---
apiVersion: v1
kind: Service
metadata:
  name: mariadbsvc
spec:
  selector:
    app: mariadbpod
  ports:
    - port: 3306
      targetPort: 3306
      nodePort: 32036
  type: NodePort
```



### 3.2 加密

#### 3.2.1 secret之opaque加密

使用base64加密

```bash
#加密
echo -n "root"| base64

#解密
echo -n "YWFh" |base64 -d
```



mariadbsecret.yml:

```bash
apiVersion: v1
kind: Secret
metadata:
  name: mariadb_secret
type: Opaque
data:
  password: YWFh
```



mariadb.yml:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadbpod
  labels:
    app: mariadbpod
spec:
  replicas: 1
  template:
    metadata:
      name: mariadbpod
      labels:
        app: mariadbpod
    spec:
      containers:
        - name: mariadbpod
          image: mariadb:10.5.2
          imagePullPolicy: IfNotPresent
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: mariadb_secret
            - name: TZ
              value: Asia/Shanghai
          args:
            - "--character-set-server=utf8mb4"
            - "--collation-server=utf8mb4_unicode_ci"
          ports:
            - containerPort: 3306
      restartPolicy: Always
  selector:
    matchLabels:
      app: mariadbpod
---
apiVersion: v1
kind: Service
metadata:
  name: mariadbsvc
spec:
  selector:
    app: mariadbpod
  ports:
    - port: 3306
      targetPort: 3306
      nodePort: 32036
  type: NodePort
```



### 3.3 configmap

通过 .properties配置文件生成 configmap

编写配置文件 myjdbc.properties (也可以是 .cnf 等等)

```properties
jdbc.driverclass=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://localhost:3306/test
jdbc.username=root
jdbc.password=aaa
```

```bash
#编写生成 configmap命令
kubectl create configmap myjdbc-config --from-file=myjdbc.properties
```

```bash
[root@master mariadb]# kubectl describe configmap myjdbc-config
Name:         myjdbc-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
myjdbc.properties:
----
jdbc.driverclass=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://localhost:3306/test
jdbc.username=root
jdbc.password=aaa
Events:  <none>
```

configmap也可以反向生成一个配置文件：

```bash
kubectl get configmaps mysqlini -o yaml > mariadbconfigmap.yml
```

### 3.4 PV&&PVC

PV就好比是一个仓库，我们需要先购买一个仓库，即定义一个PV存储服务，例如CEPH,NFS,LocalHostpath等等。

PVC就好比租户，pv和pvc是一对一绑定的，挂载到POD中，一个pvc可以被多个pod挂载。

mariadbpv.yml:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadbpv
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 500M
  hostPath:
    path: /data/mariadb
    type: DirectoryOrCreate
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  volumeMode: Filesystem
```

mariadbpvc.yml:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadbpvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 200M
```

mariadb.yml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadbdeploy
  labels:
    app: mariadbdeploy
spec:
  replicas: 1
  template:
    metadata:
      name: mariadbdeploy
      labels:
        app: mariadbdeploy
    spec:
      containers:
        - name: mariadbdeploy
          image: mariadb:10.5.2
          imagePullPolicy: IfNotPresent
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: mariadbsecret
            - name: TZ
              value: Asia/Shanghai
          args:
            - "--character-set-server=utf8mb4"
            - "--collation-server=utf8mb4_unicode_ci"
          ports:
            - containerPort: 3306
          volumeMounts:
            - mountPath: /var/lib/mysql
              name: volume-mariadb
      restartPolicy: Always
      volumes:
        - name: volume-mariadb
          persistentVolumeClaim:
            claimName: mariadbpvc
  selector:
    matchLabels:
      app: mariadbdeploy
---
apiVersion: v1
kind: Service
metadata:
  name: mariadbsvc
spec:
  selector:
    app: mariadbdeploy
  ports:
    - port: 3306
      targetPort: 3306
      nodePort: 32036
  type: NodePort
```



### 3.5 NFS存储卷

#### 3.5.1 NFS安装

```bash
yum install -y nfs-utils rpcbind 
```













































