FROM ubuntu:20.04 AS builder

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget ca-certificates gnupg unzip tar xz-utils bash \
        tzdata locales gettext \
        less vim nano lsof procps parallel software-properties-common passwd \
        net-tools iproute2 iputils-ping dnsutils traceroute telnet nmap socat tcpdump \
        openssh-client rsync \
        build-essential make cmake pkg-config g++ autoconf automake libtool \
        python3 python3-pip python3-dev python3-venv libffi-dev libssl-dev awscli \
        default-jdk ca-certificates-java \
        zip bzip2 gzip p7zip-full \
        jq git git-restore-mtime htop tree file man-db && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget -q https://get.helm.sh/helm-v3.15.0-linux-${TARGETARCH}.tar.gz && \
    tar -zxf helm-v3.15.0-linux-${TARGETARCH}.tar.gz && \
    mv linux-${TARGETARCH}/helm /usr/local/bin/helm && \
    rm -rf linux-${TARGETARCH} helm-v3.15.0-linux-${TARGETARCH}.tar.gz

RUN KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt) && \
    curl -fsSL \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
      -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu focal stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli containerd.io && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN case "${TARGETARCH}" in \
      amd64) COMPOSE_ARCH="x86_64" ;; \
      arm64) COMPOSE_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL \
      "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-${COMPOSE_ARCH}" \
      -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

RUN TERRAFORM_VERSION=1.6.0 && \
    wget -q \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" && \
    unzip \
      "terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
      -d /usr/local/bin && \
    rm -f "terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"


FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

COPY --from=builder / /

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux && \
    helm version --short && \
    kubectl version --client && \
    docker --version && \
    docker-compose --version && \
    terraform -version && \
    gcloud version && \
    aws --version && \
    python3 --version && \
    java -version
