## What are Admission Controllers

> An admission controller is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object, but after the request is authenticated and authorized. Admission controllers may be validating, mutating, or both. Mutating controllers may modify objects related to the requests they admit; validating controllers may not. Admission controllers limit requests to create, delete, modify objects. Admission controllers do not (and cannot) block requests to read (get, watch or list) objects.