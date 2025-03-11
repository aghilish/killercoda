# Step 2: Initialize a Kubebuilder Project

Let’s create a new Kubebuilder project for our "Task" resource.

Create a directory and initialize the project:

```shell
mkdir task-operator && cd task-operator
kubebuilder init --repo example.com/task-operator --domain example.com
```{{exec}}

This sets up a Go module under `example.com/task-operator` with the domain `example.com`. The project includes a `Makefile` and scaffolding files.

Check the generated `Makefile`:

```shell
make help
```{{exec}}

This lists available targets like `generate`, `manifests`, and `run`, which we’ll use later.