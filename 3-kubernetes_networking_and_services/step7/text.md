* let's look into core-dns

<details>
  <summary>Solution</summary>
    <pre><code>    
        kubectl expose deployment evsa --type=ClusterIP --port=80
    </code></pre>
</details>



* ok now let's try accessing the container via another pod

<details>
  <summary>Solution</summary>
    <pre><code>    
       k run -it test --image=yauritux/busybox-curl sh
       curl evsa
       cat /etc/resolv.conf
       curl evsa.default
       curl evsa.default.svc
       curl evsa.default.svc.cluster.local
    </code></pre>
</details>