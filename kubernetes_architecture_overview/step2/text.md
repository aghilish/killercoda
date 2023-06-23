
* exec into the containers and inpspect the process id of the sleep command.
  what process id has the sleep command ?

* exit out of the container.
  list the sleep processes on the control plane.
  what process ids do they have ?

<details>
  <summary>Solution part 1</summary>
    <pre><code>    
        docker exec -it sleepy1 sh
        # ps
    </code></pre>
    <pre><code>    
        docker exec -it sleepy2 sh
        # ps
    </code></pre>
    both sleep commands have process id 1
</details>

<details>
  <summary>Solution part 2</summary>
    <pre><code>    
        ps aux | grep sleep
    </code></pre>
    <p>
    the process ids are different from the one inside the container.
    This means docker runtime is sharing the kernel's process space between the containers.
    </p> 
</details>