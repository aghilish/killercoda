Now Let us install `Kubebuilder` into our environment.

```shell
# download kubebuilder and install locally.
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/
```{{exec}}

Let us make sure we have the latest version of GO installed.
```shell
curl -OL  https://go.dev/dl/go1.22.3.linux-amd64.tar.gz \
&&  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin
```{{exec}}

And scaffold a kubebuilder application.

```shell
mkdir operator-tutorial
```{{exec}}
```shell
cd operator-tutorial
```{{exec}}
```shell
kubebuilder init --repo example.com
```{{exec}}

let us have a closer look at the make file first.
make targets are the commands that are used for different development lifecycle steps

```shell
make help
```{{exec}}

to run your kubebuilder application locally
```shell
make run
```

now let's have a look at the `run` target and all the prerequisite comamnds that need to run
it looks something like this
```shell
.PHONY: run
run: manifests generate fmt vet ## Run a controller from your host.
	go run ./cmd/main.go
```

> so the targets that need to run before we can run our applications are 
> 1. `manifests` and `generate` which both have controller-gen as prerequisite and generate some golang code and yaml manifests 
> 2. the code is formatted by `fmt` 
> 3. validated by `vet` 
> 4. run will run the go application by refering to the application entrypoint at ./cmd/main.go 