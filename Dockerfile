FROM registry.access.redhat.com/ubi9/ubi:latest
RUN yum -y install git-core && yum clean all
