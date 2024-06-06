FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN sed -i.bak -r 's@//.*ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list && \
    apt update && \
    apt install -y xz-utils tar curl jq vim sudo gdb wget git ccache pkg-config lsb-release \
        python3 python3-pip python3.8 python3.8-dev \
        libssl1.1 libmsgpack-dev numactl build-essential binutils lintian \
        patchelf

SHELL ["/bin/bash", "-c"]
RUN echo $'[global]\n\
index-url = https://pypi.tuna.tsinghua.edu.cn/simple\n\
[install]\n\
trusted-host = https://pypi.tuna.tsinghua.edu.cn' > /etc/pip.conf

RUN python3.8 -m pip install -U pip wheel scikit-build setuptools && \
    python3.8 -m pip install cmake

ADD setup/env /tmp/env
RUN . /tmp/env && \
    if getent group $DEV_GROUP 2>/dev/null 1>/dev/null ; then \
        echo group $DEV_GROUP already exist ; \
    elif getent group $DEV_GID 2>/dev/null 1>/dev/null ; then \
        echo group $DEV_GID already exist ; \
    else \
        groupadd -g $DEV_GID $DEV_GROUP ; \
    fi ; \
    if id $DEV_USER 2>/dev/null 1>/dev/null ; then \
        echo user $DEV_USER already exist ; \
        exit 1 ; \
    elif id $DEV_UID 2>/dev/null 1>/dev/null ; then \
        echo user $DEV_UID already exist ; \
        exit 1 ; \
    else \
        useradd -g $DEV_GID -u $DEV_UID -m -d $DEV_HOME -s /bin/bash $DEV_USER ; \
    fi && \
    echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

# go
RUN cd /usr/local && \
    curl -fL https://studygolang.com/dl/golang/go1.22.0.linux-amd64.tar.gz | tar xz

ENV MACA_PATH=/opt/maca \
    CUDA_PATH=/opt/maca/tools/cu-bridge \
    CUCC_PATH=/opt/maca/tools/cu-bridge \
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/maca/lib \
    PATH=/usr/local/go/bin:${PATH} \
    GOPROXY=goproxy.cn
