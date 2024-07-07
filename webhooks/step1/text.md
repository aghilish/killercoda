## What are Admission Controllers

> An admission controller is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object, but after the request is authenticated and authorized. Admission controllers may be validating, mutating, or both. Mutating controllers may modify objects related to the requests they admit; validating controllers may not. Admission controllers limit requests to create, delete, modify objects. Admission controllers do not (and cannot) block requests to read (get, watch or list) objects.

[Kubernetes Docs on Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

## How can we turn them on ?

By passing their names to the --enable-admission-plugins option.
```bash
kube-apiserver --enable-admission-plugins=NamespaceLifecycle,LimitRanger ...
```

## Which ones are enabled by default ?

```bash
CertificateApproval, CertificateSigning, CertificateSubjectRestriction, DefaultIngressClass, DefaultStorageClass, DefaultTolerationSeconds, LimitRanger, NamespaceLifecycle, PersistentVolumeClaimResize, PodSecurity, Priority, ResourceQuota, RuntimeClass, ServiceAccount, StorageObjectInUseProtection, TaintNodesByCondition, ValidatingAdmissionPolicy, MutatingAdmissionWebhook,ValidatingAdmissionWebhook
```