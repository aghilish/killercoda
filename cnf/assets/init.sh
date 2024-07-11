#!/bin/bash

# install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

# install k9s
curl -L -O https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb \
&& dpkg -i k9s_linux_amd64.deb

# install crossplane cli
curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh

# mark init finished
touch /ks/.initfinished