* let's take a closer look at the bookinfo gateway

<details>
  <summary>Solution</summary>
    <pre><code> 
      cat samples/bookinfo/networking/bookinfo-gateway.yaml
    </code></pre>
</details>
compare the selector and the label set on the ingress gateway


* let's take a look at the ingress labels
<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl describe deployments.apps -n istio-system istio-ingressgateway
    </code></pre>
</details>

* let's take a closer look at the bookinfo virtualservice
<details>
  <summary>Solution</summary>
    <pre><code> 
    cat samples/bookinfo/networking/bookinfo-gateway.yaml
    </code></pre>
</details>
please notice the gateway name

* let's take a closer look at the bookinfo destination rule
<details>
  <summary>Solution</summary>
    <pre><code> 
    cat samples/bookinfo/networking/destination-rule-all.yaml
    </code></pre>
</details>
please notice the subsets and pod labels