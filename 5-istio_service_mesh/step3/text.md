* Access app
Now we port-forward to the Istio ingressgateway service:
<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl port-forward -n istio-system --address 0.0.0.0 service/istio-ingressgateway 1234:80
    </code></pre>
</details>

Finally [ACCESS]({{TRAFFIC_HOST1_1234}}/productpage) the Bookinfo app through Istio <small>(or [select the port here]({{TRAFFIC_SELECTOR}}))</small>.