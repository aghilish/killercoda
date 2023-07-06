* let's create a simple nginx pod first

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl run nginx --image=nginx
    </code></pre>
</details>

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


* ok can you try acccessing your container from a node ?

<details>
  <summary>Solution</summary>
  we need to add the selector to the service definition
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
          selector:
            run: nginx            
    </code></pre>
</details>

* ok can you try acccessing your container from a node ?

<details>
  <summary>Solution</summary>
  we need to add the selector to the service definition, otherwise the svc object 
  won't know to which pod it should direct the traffic 
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
          selector:
            run: nginx            
    </code></pre>
</details>


* ok now let's try accessing the container via a node

<details>
  <summary>Solution</summary>
    <pre><code>    
       curl http://$NODE01_IP:30080
    </code></pre>
</details>