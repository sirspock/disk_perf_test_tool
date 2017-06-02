FROM centos:7
MAINTAINER Maximiliano Osorio

RUN yum install -y \ 
	epel-release

RUN yum install -y \
	python-devel \
	python-virtualenv \
	python-pip \
	libvirt-python \
	libffi-devel \
	openssl-devel \
	python-setuptools \
	git \
	vim \
	curl \
	wget \
	pyOpenSSL \
	python-novaclient \
	python-cinderclient \
    python-keystoneclient \
    python-glanceclient \
    python-ecdsa \
    scipy \
    numpy \
    python-matplotlib \
    python-psutil \
    python-pip \
    fio


RUN git clone https://github.com/sirspock/disk_perf_test_tool.git \
    /opt/disk_perf_tool

RUN cd /opt/disk_perf_tool/scripts; pip install oktest iso8601==0.1.10

RUN ["/bin/bash"]