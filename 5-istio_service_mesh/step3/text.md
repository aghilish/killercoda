* Access app

First we need to make sure the networking resources for our application are configured

Now we port-forward to the Istio ingressgateway service:
<details>
  <summary>Solution</summary>
    <pre><code> 
      kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
      kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
      kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
      kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    </code></pre>
</details>



Now we port-forward to the Istio ingressgateway service:
<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl port-forward -n istio-system --address 0.0.0.0 service/istio-ingressgateway 1234:80
    </code></pre>
</details>

Finally [ACCESS]({{TRAFFIC_HOST1_1234}}/productpage) the Bookinfo app through Istio <small>(or [select the port here]({{TRAFFIC_SELECTOR}}))</small>.

* kiali dashboard 
kubectl port-forward -n istio-system --address 0.0.0.0 service/kiali 1234:20001
while sleep 0.01;do curl -sS 'https://1d669b51-28bc-4a90-8201-1af6c02dd733-10-244-4-183-1234.spch.r.killercoda.com/productpage'\ &> /dev/null; done

/kiali/console