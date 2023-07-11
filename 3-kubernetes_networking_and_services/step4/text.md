* let's create a deployment from the `nginx` image

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl create deploy evsa --image=nginx
    </code></pre>
</details>

* create a simple nodeport service using the imperative approach

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl expose deployment evsa --type=NodePort --port=80
    </code></pre>
</details>


* ok now let's try accessing the container via a node

<details>
  <summary>Solution</summary>
    <pre><code>    
       curl http://$NODE01_IP:$NODEPORT
    </code></pre>
</details>