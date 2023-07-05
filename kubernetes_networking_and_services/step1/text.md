
* let's start with docker 
* let's create an nginx container called `jack` and then inpect it
* what is the container ip address ?
* what is the node ip address ?

<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
      docker run --name=jack -d nginx 
    </code>
    <code>
      docker inspect jack | grep IPAddress
    </code>
    <code>
      kubectl get nodes -owide
    </code>
      </pre>
    </p>
</details>

* can you exec into the container and curl localhost ?
* can you map a host port on a new nignx container let's call it `joe` ?
* can you curl the container from the host ?


<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
      docker exec -it jack sh
      curl localhost
    </code>
    <code>
      docker run -d -p 8080:80 --name=joe nginx
    </code>
    <code>
      curl localhost:8080
    </code>
      </pre>
    </p>
</details>