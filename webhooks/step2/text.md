## Dynamic Admission Control
> In addition to compiled-in admission plugins, admission plugins can be developed as extensions and run as webhooks configured at runtime. 

## What are Admission Webhooks
> Admission webhooks are HTTP callbacks that receive admission requests and do something with them. You can define two types of admission webhooks, validating admission webhook and mutating admission webhook. Mutating admission webhooks are invoked first, and can modify objects sent to the API server to enforce custom defaults. After all object modifications are complete, and after the incoming object is validated by the API server, validating admission webhooks are invoked and can reject requests to enforce custom policies.

> Admission Webhooks can run inside or outside the cluster. If We deploy them inside the cluster, we can leverage cert manager for automatically injecting the ssl certificate.

> Dynamic Admission Control [Details](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
<img src="../assets/webhook-white.png" alt="Dynamic Admission Control" width="100%">
