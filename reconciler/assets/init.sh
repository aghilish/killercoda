#!/bin/bash

# install go
curl -OL  https://go.dev/dl/go1.25.0.linux-amd64.tar.gz \
&&  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin

# install kubebuilder
# download kubebuilder and install locally.
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/

# install npm
apt install npm -y
# mark init finished
touch /ks/.initfinished