
* create a new deployment called `taapi` using the `nginx` image and with `3` replicas
<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl create deployment taapi --image=nginx --replicas=3
    </code></pre>
</details>

* try deleting one of the pods, what happens ?

<details>
  <summary>Solution</summary>
    <pre>
        <code>
        kubectl delete pod taapi-****-**
        </code>
    </pre>
</details>

* inspect the deployment events

<details>
  <summary>Solution</summary>
    <pre>
        <code>
        kubectl describe deployment taapi
        </code>
        <code>
        kubectl rollout status deployment taapi
        </code>
        <code>
        kubectl rollout history deployment taapi
        </code>
    </pre>
</details>

* manually scale `taapi` up to `5` replicas
<details>
  <summary>Solution</summary>
    <pre>
        <code>
        kubectl scale deployment taapi --replicas 5
        </code>
    </pre>
</details>

* manually change `taapi`s deployment image to `busybox`
<details>
  <summary>Solution</summary>
    <pre>
        <code>
        k set image deployment/taapi nginx=busybox
        </code>
    </pre>
</details>
