
* create a simple nginx pod called `test` using commandline (imperative)

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl run test --image=nginx
    </code></pre>
</details>

* create a simple nginx pod called `test2` in a declarative

<details>
  <summary>Solution</summary>
    <pre>
        <code>
        apiVersion: v1
        kind: Pod
        metadata:
            name: jack-the-webserver
        spec:
            containers:
            - name: nginx
                image: nginx        
        #kubectl run test --image=nginx
        </code>
    </pre>
</details>
