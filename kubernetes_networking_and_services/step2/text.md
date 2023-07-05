
* which network are the k8s nodes in ?  
* which network are the k8s pods in ? 
* which networs are the k8s services in ?

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl get nodes -owide
        ip addr 
    </code></pre>
    <pre><code>    
        kubectl get pods -owide
    </code></pre>
    <pre><code>    
        kubectl get nodes -owide
    </code></pre>
</details>