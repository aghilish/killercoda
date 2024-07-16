Let's create our own function
```bash
FUNCTION_NAME=function-cnf
crossplane beta xpkg init $FUNCTION_NAME function-template-go -d $FUNCTION_NAME
```

```bash
cd $FUNCTION_NAME
go run . --insecure --debug
```

```bash
cd example
crossplane beta render xr.yaml composition.yaml functions.yaml -r 
```

fn.go
```bash
curl -s https://raw.githubusercontent.com/aghilish/function-cnf/main/fn.go > fn.go
```
input/v1beta1/input.go
```go
type Input struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	// Example is an example field. Replace it with whatever input you need. :)
	Count int `json:"count"`
}
```

example/composition.yaml
```bash
cat <<EOF > example/composition.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: function-cnf
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1
    kind: XR
  mode: Pipeline
  pipeline:
  - step: run-the-template
    functionRef:
      name: function-cnf
    input:
      apiVersion: template.fn.crossplane.io/v1beta1
      kind: Input
      count: 3
EOF
```

```bash
go mod tidy
```

```bash
go generate ./...
```

```bash
go run . --insecure --debug
```

```bash
crossplane beta render xr.yaml composition.yaml functions.yaml -r 
```

```bash
cat <<EOF > example/extensions.yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.2.0
---
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
 name: xrs.example.crossplane.io
spec:
  group: example.crossplane.io
  names:
    kind: XR
    plural: xrs
  versions:
  - name: v1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
EOF
```


```bash
crossplane beta render xr.yaml composition.yaml functions.yaml -x | crossplane beta validate extensions.yaml --cache-dir="${HOME}/.crossplane/cache" -
```
```bash
curl -s https://raw.githubusercontent.com/aghilish/function-cnf/main/Dockerfile > Dockerfile
```
```bash
docker build --tag ttl.sh/function-cnf:1h .
```

```bash
docker push ttl.sh/function-cnf:1h
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-cnf
spec:
  package: ttl.sh/function-cnf:1h
EOF
```

```bash
kubectl get functions -w
```


```bash
kubectl apply -f extensions.yaml
kubectl apply -f composition.yaml
kubectl apply -f xr.yaml
```

To mark XR as ready when the buckets are ready we can use another function

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-auto-ready
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-auto-ready:v0.2.1
EOF
```


```bash
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: function-cnf
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1
    kind: XR
  mode: Pipeline
  pipeline:
  - step: run-the-template
    functionRef:
      name: function-cnf
    input:
      apiVersion: template.fn.crossplane.io/v1beta1
      kind: Input
      count: 3
  - step: automatically-detect-ready-composed-resources
    functionRef:
      name: function-auto-ready
EOF
```

