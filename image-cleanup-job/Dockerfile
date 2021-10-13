FROM debian:latest

RUN apt install -y bash grep 
RUN apt-get update
RUN apt install -y apt-transport-https gnupg2 curl

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

# Install prerequisites for PowerShell
RUN apt-get update
RUN apt install -y \
    ca-certificates \
    less \
    tzdata \
    kubectl

# Install libssl1.0 (not in apt repo)
# RUN curl -O http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.7_amd64.deb
# RUN dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.7_amd64.deb

# Install libicu55 (not in apt repo)
RUN curl -O http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu55_55.1-7_amd64.deb
RUN dpkg -i libicu55_55.1-7_amd64.deb

# Download the Microsoft repository GPG keys
RUN curl -O https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
RUN dpkg -i packages-microsoft-prod.deb

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Update the list of products
RUN apt-get update

# Install PowerShell
RUN apt-get install -y powershell dos2unix

# Install cleanup scripts
RUN mkdir job
ADD wrapper.sh /job/wrapper.sh
RUN dos2unix /job/wrapper.sh
ADD Run-ImageCleanup.ps1 /job/Run-ImageCleanup.ps1
COPY worker-template/templates/*.yaml /job/chart/image-cleanup-worker/templates/
COPY worker-template/*.yaml /job/chart/image-cleanup-worker/
COPY version /job/chart/image-cleanup-worker/version

WORKDIR /job
CMD ["/bin/bash", "./wrapper.sh"]
