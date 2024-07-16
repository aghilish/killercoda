Let's create our own function
```bash
FUNCTION_NAME=function-cnf
crossplane beta xpkg init $FUNCTION_NAME function-template-go -d $FUNCTION_NAME
```{{exec}}

```bash
cd $FUNCTION_NAME
go run . --insecure --debug
```{{exec}}

```bash
cd example
crossplane beta render xr.yaml composition.yaml functions.yaml -r 
```{{exec}}

fn.go
```bash
package main

import (
	"context"
	"fmt"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/utils/ptr"

	s3v1beta "github.com/upbound/provider-aws/apis/s3/v1beta1"

	v1beta1 "github.com/crossplane/function-cnf/input/v1beta1"
	"github.com/crossplane/crossplane-runtime/pkg/errors"
	"github.com/crossplane/crossplane-runtime/pkg/logging"
	fnv1beta1 "github.com/crossplane/function-sdk-go/proto/v1beta1"
	"github.com/crossplane/function-sdk-go/request"
	"github.com/crossplane/function-sdk-go/resource"
	"github.com/crossplane/function-sdk-go/resource/composed"
	"github.com/crossplane/function-sdk-go/response"
)

// Function returns whatever response you ask it to.
type Function struct {
	fnv1beta1.UnimplementedFunctionRunnerServiceServer

	log logging.Logger
}

// RunFunction runs the Function.
func (f *Function) RunFunction(_ context.Context, req *fnv1beta1.RunFunctionRequest) (*fnv1beta1.RunFunctionResponse, error) {
	f.log.Info("Running function", "tag", req.GetMeta().GetTag())

	rsp := response.To(req, response.DefaultTTL)

	in := &v1beta1.Input{}
	if err := request.GetInput(req, in); err != nil {
		response.Fatal(rsp, errors.Wrapf(err, "cannot get Function input from %T", req))
		return rsp, nil
	}

	_ = s3v1beta.AddToScheme(composed.Scheme)
	desired, err := request.GetDesiredComposedResources(req)
	if err != nil {
		response.Fatal(rsp, errors.Wrapf(err, "cannot get desired resources from %T", req))
		return rsp, nil
	}

	// Generate in.Count number of S3 buckets
	for i := 1; i <= int(in.Count); i++ {
		name := fmt.Sprintf("cnf-bucket-%d", i)
		b := &s3v1beta.Bucket{
			ObjectMeta: metav1.ObjectMeta{
				Annotations: map[string]string{
					"crossplane.io/external-name": name,
				},
			},
			Spec: s3v1beta.BucketSpec{
				ForProvider: s3v1beta.BucketParameters{
					Region: ptr.To[string]("eu-central-1"),
				},
			},
		}
		cd, _ := composed.From(b)
		desired[resource.Name(fmt.Sprintf("xbuckets-%s", name))] = &resource.DesiredComposed{Resource: cd}
	}

	if err := response.SetDesiredComposedResources(rsp, desired); err != nil {
		response.Fatal(rsp, errors.Wrapf(err, "cannot set desired composed resources in %T", rsp))
		return rsp, nil
	}

	f.log.Info("Buckets created", "count", in.Count)
	return rsp, nil
}
```{{copy}}
input/v1beta1/input.go
```go
type Input struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	// Example is an example field. Replace it with whatever input you need. :)
	Count int `json:"count"`
}
```{{copy}}

example/composition.yaml
```yaml
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
```

```bash
go mod tidy
```{{exec}}

```bash
go generate ./...
```{{exec}}

```bash
go build
```{{exec}}

```bash
go run . --insecure --debug
```{{exec}}

```bash
crossplane beta render xr.yaml composition.yaml functions.yaml -r 
```{{exec}}

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
```{{exec}}


```bash
crossplane beta render xr.yaml composition.yaml functions.yaml -x | crossplane beta validate extensions.yaml --cache-dir="${HOME}/.crossplane/cache" -
```{{exec}}

```bash
docker build --tag c8n.io/aghilish/function-cnf:v0.0.1 .
```{{exec}}

```bash
docker push c8n.io/aghilish/function-cnf:v0.0.1
```{{exec}}

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-cnf
spec:
  package: c8n.io/aghilish/function-cnf:v0.0.1 
EOF
```{{exec}}

```bash
kubectl get functions -w
```{{exec}}


```bash
kubectl apply -f extensions.yaml
kubectl apply -f composition.yaml
kubectl apply -f xr.yaml
```{{exec}}

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
```{{exec}}


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
```{{exec}}

