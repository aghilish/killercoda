
* download and install istio

<details>
  <summary>Solution</summary>
    <pre><code>    
        curl -L https://istio.io/downloadIstio | sh -
        cd istio-\<version-number\>
        export PATH=$PWD/bin:$PATH
        istioctl install --set profile=demo -y
    </code></pre>
</details>

* cd istio-\<version-number\>/manifests/profiles/
  <br/>
  what do different profiles mean ?
<details>
  <summary>Solution</summary>
    <pre><code>    
        istioctl install --help
    </code></pre>
    different components, mesh config etc.
</details>

* verify installation
<details>
  <summary>Solution</summary>
    <pre><code>    
        istioctl verify-install
    </code></pre>
</details>