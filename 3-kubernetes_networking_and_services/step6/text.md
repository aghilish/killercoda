* let's create a loadbalancer service

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl expose deployment evsa --type=LoadBalancer --port=80
    </code></pre>
</details>


* let's list the svc. how do you explain the pending state of the external ip ?

<details>
  <summary>Solution</summary>
    <pre><code>    
       k get svc -owide
    </code></pre>
    the external ip stays in pending state 
    b/c this is kubeadm setup running in a vm 
    and  there is no load balancer provisioning available
</details>