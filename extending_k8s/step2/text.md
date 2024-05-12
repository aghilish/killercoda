Now Let us install `Kubebuilder` into our environment.

```shell
# download kubebuilder and install locally.
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/
```{{exec}}

And scaffold a kubebuilder application.

```shell
mkdir operator-tutorial
cd operator-tutorial
kubebuilder init --repo example.com
```{{exec}}

let us have a closer look at the make file first.
make targets are the commands that are used for different development lifecycle steps

```shell
make help
```{{exec}}