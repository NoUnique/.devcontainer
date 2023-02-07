ARG MIRROR_DOCKERIO=docker.io
FROM ${MIRROR_DOCKERIO}/ubuntu:20.04

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# To remove debconf build warnings
ARG DEBIAN_FRONTEND=noninteractive

## Set proxy & ca-certificates
ARG SET_PROXY_SETTING
ARG http_proxy
ARG https_proxy
ARG no_proxy
COPY .devcontainer/set_proxy_setting.sh /tmp/set_proxy_setting.sh
RUN sh /tmp/set_proxy_setting.sh

# Change locale to fix encoding error on mail-parser install
ARG LC=ko_KR.UTF-8
RUN apt-get update \
 && apt-get install --no-install-suggests -y \
    locales \
 && locale-gen en_US.UTF-8 \
 && locale-gen ${LC} \
    ;
# Set default locale for the environment
ENV LC_ALL=C \
    LANG=${LC}

# Change the timezone
ARG TZ=Asia/Seoul
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    ;

# Install essential programs
RUN apt-get update \
 && apt-get install --no-install-suggests -y \
    python3.10 \
    python3-pip \
    ;

WORKDIR /app

COPY . .
RUN pip3 install -r requirements.txt

ENV PYTHONPATH=/app
CMD ["python", "main.py"]
