
* check out kubectl version using the cli tool itself and the curl command.

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl version
        KUBE_API=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
        curl -k $KUBE_API/version
    </code></pre>
</details>