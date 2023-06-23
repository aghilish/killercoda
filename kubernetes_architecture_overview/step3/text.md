
* list kubernetes components that run as a pod.
* ssh into the worker node and inspect the kubelet process running inside it



<details>
  <summary>Solution part 1</summary>
    <pre><code>    
        kubectl get pods -n kube-system
    </code></pre>
</details>

<details>
  <summary>Solution part 2</summary>
    <pre><code>    
        kubectl get nodes
    </code></pre>
    worker node is called `node01`
    we need to ssh into that.
    <pre><code>    
        ssh node01
    </code></pre>
    next we list the processes and filter for kubelet
    <pre><code>    
        ps aux | grep kubelet
    </code></pre>
</details>
