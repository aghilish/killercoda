## Crossplane Compositions
> Using managed instances is not scalable. Crossplane compositions enable us to build complex infrastructure with simple interfaces. The simple interface is what platform engineers offer to end users.

### Restaurant Analogy
 <img src="../assets/restaurant.png" alt="Restaurant" width="1000" height="300">

### Crossplane Compositions
 <img src="../assets/xcompositions.png" alt="Restaurant" width="1000" height="300">

### Compositions 1.0
 <img src="../assets/xcompositions1.0.png" alt="Restaurant" width="1000" height="300">

 The providers start reconciling the managed resources as soon as they are persisted to the etcd.

### Example, AWS SQL Database
Let's see how a postgres database can be provisioned
```bash
cat 1.0/defintion.yaml
```{{exec}}
```bash
cat 1.0/aws.yaml
```{{exec}}
```bash
cat 1.0/claim.yaml
```