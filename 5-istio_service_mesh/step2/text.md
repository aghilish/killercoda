
* deploy the first application

<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
        kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
      </code>
    </pre>
  </p>
</details>

* How many containers are running in each pod? 

<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl get pods
    </code></pre>
</details>

* let's figure out what's going on 

<details>
  <summary>Solution</summary>
    <pre><code> 
    istioctl analyze
    </code></pre>
</details>

* let's enable sidecar injection 

<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl label namespace default istio-injection=enabled
    </code></pre>
</details>

* let's restart the deployments
<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl rollout restart deployment
    </code></pre>
</details>

* How many containers are running in each pod now?
