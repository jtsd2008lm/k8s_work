FROM registry.cn-beijing.aliyuncs.com/centosd/centos:latest
COPY kubernate_work-1.0.jar /app/kubernate_work-1.0.jar
MAINTAINER limeng 
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app/kubernate_work-1.0.jar"]
