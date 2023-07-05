
* create a simple nodeport service using the declartive approach

<details>
  <summary>Solution</summary>
    <pre><code>    
        apiVersion: v1
        kind: Service
        metadata:
          name: jack-the-server
        spec:
          type: NodePort
          ports:
            - targetPort: 80
              port: 80
              nodePort: 30080
    </code></pre>
</details>

* let's list the services

<details>
  <summary>Solution</summary>
    <pre><code>    
       kubectl get svc -owide
    </code></pre>
</details>
