
* Create two docker containers from the busybox image and name them `sleepy1` and `sleepy2` and run the following sleep commands inside them.
  * `sleep 1000`
  * `sleep 2000`

<details>
  <summary>Solution</summary>
    <pre><code>    
        docker run -d --name=sleepy1 busybox sleep 1000
        docker run -d --name=sleepy2 busybox sleep 2000
    </code></pre>
</details>