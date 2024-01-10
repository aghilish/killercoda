> Now let's enable auto sync on the UI. Please also make sure you enable `PRUNE RESOURCES` and `SELF HEAL` options.

Now let's showcase the self healing.
Let's delete the deployment and at the same time have a look on the UI

```jsx
kubectl -n guestbook delete deploy guestbook-ui
```

What happens ?
It magically healed itself. Pretty amazing, huh ?

And for the self pruning we can try renaming the guestbook-ui deployment to something else.

Once again Argo CD detects the drift from the desired state and prunes the undesired deployment!
