
* which network are the k8s nodes in ?  
* which network are the k8s pods in ? 
* which networs are the k8s services in ?

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl get nodes -owide
        ip addr 
    </code></pre>
    don't forget to create a new pod in the default namespace first
    <pre><code>
        kubectl run nginx --image=nginx
        kubectl get pods -owide
    </code></pre>
    <pre><code>    
        kubectl get svc -owide
    </code></pre>
</details>