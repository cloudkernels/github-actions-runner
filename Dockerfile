#FROM quay.io/evryfs/base-ubuntu:bionic-20200921
#FROM quay.io/evryfs/base-ubuntu:focal-20201106
FROM nubificus/vaccel-deps:latest

ARG RUNNER_VERSION=2.277.1

# This the release tag of virtual-environments: https://github.com/actions/virtual-environments/releases
ARG VIRTUAL_ENVIRONMENT_VERSION=ubuntu18/20200817.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install base packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo=1.8.* \
    lsb-release=9.* \
    software-properties-common=0.96.* \
    gnupg-agent=2.2.* \
    openssh-client=1:7.* \
    curl \
    make=4.*\
    jq=1.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update git.
RUN add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get -y install --no-install-recommends git && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install docker cli.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get install -y --no-install-recommends docker-ce-cli=5:19.03.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts.
COPY scripts/install-from-virtual-env /usr/local/bin/install-from-virtual-env

# Install base packages from the virtual environment.
RUN install-from-virtual-env basic
RUN install-from-virtual-env python
RUN install-from-virtual-env aws
RUN install-from-virtual-env docker-compose
RUN install-from-virtual-env nodejs

# Install runner and its dependencies.
RUN useradd -mr -d /home/runner -G sudo -u 1000 runner && \
    curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xzvC /home/runner && \
    /home/runner/bin/installdependencies.sh

# Clean apt cache.
RUN apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entrypoint.sh remove_runner.sh /
WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
