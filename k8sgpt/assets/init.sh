#!/bin/bash

# install k9s
curl -L -O https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb \
&& dpkg -i k9s_linux_amd64.deb

# install k8sgpt cli
curl -L -O https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.24/k8sgpt_amd64.deb \
&& dpkg -i --force-overwrite k8sgpt_amd64.deb

# install go
curl -OL  https://go.dev/dl/go1.22.3.linux-amd64.tar.gz \
&&  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin

# install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# mark init finished
touch /ks/.initfinished