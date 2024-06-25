## What are Admission Controllers

> An admission controller is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object, but after the request is authenticated and authorized. Admission controllers may be validating, mutating, or both. Mutating controllers may modify objects related to the requests they admit; validating controllers may not. Admission controllers limit requests to create, delete, modify objects. Admission controllers do not (and cannot) block requests to read (get, watch or list) objects. 

> The admission controllers in Kubernetes 1.30 consist of the list below, are compiled into the kube-apiserver binary, and may only be configured by the cluster administrator.

## Why do we need them ?
> Why do I need them? Several important features of Kubernetes require an admission controller to be enabled in order to properly support the feature. As a result, a Kubernetes API server that is not properly configured with the right set of admission controllers is an incomplete server and will not support all the features you expect.

## How can we turn them on ?
```bash
kube-apiserver --enable-admission-plugins=NamespaceLifecycle,LimitRanger ...
```
## Which ones are enabled by default ?
```bash
# to get the list we can run 
kube-apiserver -h | grep enable-admission-plugins
# these are enabled by default

#CertificateApproval, CertificateSigning, CertificateSubjectRestriction, DefaultIngressClass, DefaultStorageClass, DefaultTolerationSeconds, LimitRanger, MutatingAdmissionWebhook, NamespaceLifecycle, PersistentVolumeClaimResize, PodSecurity, Priority, ResourceQuota, RuntimeClass, ServiceAccount, StorageObjectInUseProtection, TaintNodesByCondition, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook

```