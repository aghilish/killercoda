# Step 10: Explore Further Resources

Great job! You’ve built a basic custom resource with Kubebuilder. Here are resources to dive deeper:

- **Kubebuilder Book**: Learn more about controllers and advanced features.  
  [https://book.kubebuilder.io](https://book.kubebuilder.io)

- **Kubernetes API Reference**: Explore CRD specs and validation.  
  [https://kubernetes.io/docs/reference/kubernetes-api/](https://kubernetes.io/docs/reference/kubernetes-api/)

- **Example Projects**: Check out real-world CRDs like `Cleaner` and `ClusterProfile`.  
  [k8s-cleaner](https://github.com/gianlucam76/k8s-cleaner) | [addon-controller](https://github.com/projectsveltos/addon-controller)

Try enhancing this lab by:
- Adding logic in `controllers/task_controller.go` to update the `Status`.
- Experimenting with more validation markers in `api/v1/task_types.go`.

What will you build next?