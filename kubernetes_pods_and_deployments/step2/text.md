
* kuberenetes yaml structure

<details>
  <summary>Api Structure</summary>
  <p>
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
    </code>
      </pre>
    </p>
</details>

* what versions does the kubernetes api support? 

<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl api-versions 
    </code></pre>
</details>

* what Kinds does the kubernetes api support? 

<details>
  <summary>Solution</summary>
    <pre><code> 
    kubectl api-resources 
    </code></pre>
</details>