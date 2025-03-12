# Step 1: Set Up Your Environment

First, let’s install the tools we need: Kubebuilder and Go.

Install Kubebuilder:

```shell
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/
```{{exec}}

Verify Kubebuilder is installed:

```shell
kubebuilder version
```{{exec}}

Next, ensure we have the latest Go version:

```shell
curl -OL https://go.dev/dl/go1.24.1.linux-amd64.tar.gz \
&& rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin
```{{exec}}

Check Go version:

```shell
go version
```{{exec}}

Your environment is now ready for Kubebuilder development!