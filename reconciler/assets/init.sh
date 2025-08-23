#!/bin/bash

# install go
curl -OL  https://go.dev/dl/go1.25.0.linux-amd64.tar.gz \
&&  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin

# install kubebuilder
version=1.0.8 # latest stable version
arch=amd64
# download the release
curl -L -O "https://github.com/kubernetes-sigs/kubebuilder/releases/download/v${version}/kubebuilder_${version}_linux_${arch}.tar.gz"

# extract the archive
tar -zxvf kubebuilder_${version}_linux_${arch}.tar.gz
mv kubebuilder_${version}_linux_${arch} kubebuilder && sudo mv kubebuilder /usr/local/

# update your PATH to include /usr/local/kubebuilder/bin
export PATH=$PATH:/usr/local/kubebuilder/bin

# install npm
apt install npm -y
# mark init finished
touch /ks/.initfinished