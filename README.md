# kos-test

This repo is about scale-testing of https://github.com/MikeSpreitzer/kube-examples/tree/add-kos/staging/kos

## Main Experiment

### Independent variables

- OPS: average operations per second from driver during cruise phase.

- NCA: number of connection agents.  Values: 600, 1200, 1800.

- POP: cruise phase nominal number of NetworkAttachments.  Values 1X, 3X, 9X for as big an X as we can manage.

- NNA: number of network-apiservers.  Values: 1, 3, 9.

- NKA: number of kube-apiservers.  Values: 1, 3, 9 if it's interesting; just 3 if not.

### Dependent variables

We have two sorts of dependent variables: global and per-node.  There is one global dependent variable: latency from
(a) when the client starts to make a request to (b) when the connection agent fulfils the request.

The per-node variables are the following cost metrics.

- CPU usage
- memory usage
- network bytes in
- network bytes out

We plan on using single-purpose nodes; we care about the per-node cost metrics
only for the nodes corresponding to certain purposes.

The purposes for whom we plan to compute the cost metrics are:

- compN: Run the KOS connection agent
- nctrlN: Run the KOS central controllers (including etcd operator for KOS etcd servers)
- napiN: Run the KOS network-apiserver
- netcdN: Run the KOS etcd servers
- kctrlN: Run the Kubernetes central controllers (including the scheduler)
- kapiN: Run the kube-apiservers
- ketcdN: Run the kube etcd servers

The purposes for whom we won't compute the cost metrics are:

- base: Operations base & run the driver
- obs: Run centralized logs/metrics services (if we have any of these)
- data: Run Prometheus server

### Development configuration

#### The r12s24 cluster

One L0 host with 64 "CPUs", 512 GB of main memory, and no persistent storage.
L1 disks are implemented by QCOW2 that is backed by L0 memory.
Thus, L0 memory consumption by L1 disks grows over time according to usage.
20 L1 nodes.

| purpose | number | CPUs | mem GB |
| ------- | ------ | ---- | ------ |
| base    |   1    |   4  |   32   |
| ketcd   |   3    |   4  |   12   |
| kapi    |   1    |   4  |   12   |
| kctrl   |   1    |   4  |   12   |
| netcd   |   3    |   4  |   12   |
| napi    |   1    |   4  |   12   |
| nctrl   |   1    |   4  |   12   |
| data    |   1    |   4  |   12   |
| comp    |   3    |   4  |    8   |

## Metrics Configuration

### Prometheus

See `metrics/prometheus`.  It is like the main KOS version, with the
following differences.

- The `main-etcd-client-tls` secret is expected to
  have the keys `ca.pem`, `cert.pem`, and `key.pem`.

## Operations

On your management machine let `/etc/ansible/hosts` be a directory
with various inventory files, writable by you.

### Kubectl configuration

On your laptop, there are two ways to make `kubectl` work without
explicit server or config arguments.  One is to `ssh
-L8080:localhost:8080 ...` to a host running a kube-apiserver with the
insecure port 8080 open.

Another is to
- copy a secured kubeconfig file to your laptop somewhere,
- change the server address inside it to `127.0.0.1`,
- `ssh -L6443:localhost:6443 ...` to a host running a kube-apiserver, and
- set your KUBECONFIG envar to point to the modified kubeconfig file.

### Creating an Ansible inventory file for L1 nodes

While logged into your management machine, with this repo's directory
current, and `kubectl` addressing your cluster:

```
export clustername=somethingappropriate
ops/make-l1-inventory.sh $clustername
```

This will create a file that is named
`/etc/ansible/hosts/${clustername}_L1` and defines an Ansible host
group named `${clustername}_L1`.

### Differentiating Kubernetes API and Control nodes

The Kubernetes deployment tech deploys all the master components
(kube-apiserver, kube-scheduler, kube-controller-manager) to both the
kapi and the kctrl nodes.  The following Ansible playbook usage trims
what is running on those nodes.

```
ansible-playbook ops/plays/diff-kctl.yaml -e clustername=$clustername
```

### Labeling nodes

While logged into your management machine, with this repo's directory
current, and `kubectl` addressing your cluster:

```
ops/label-nodes.sh
```

To display the results:
```
kubectl get Node -L kos-role/ketcd,kos-role/kapi,kos-role/kctrl,kos-role/netcd,kos-role/napi,kos-role/nctrl,kos-role/netcd-op,kos-role/comp,kos-role/data
```

### Installing cadvisor on the nodes

(Don't do it this way, cadvisor and OVS should already be installed.)


```
ansible-playbook ops/plays/install-cadvisor.yaml -e clustername=$clustername -f 8
```

## Data storage

Data will be stored in an IBM Cloud Object Storage (COS) instance.

We will use the Minio client, as described at
https://cloud.ibm.com/docs/services/cloud-object-storage?topic=cloud-object-storage-minio
.  The binary is at https://dl.min.io/client/mc/release/linux-amd64/mc
.  The last tested release was 2020-02-25T18-10-03Z and its SHA256 hash is
2b679947158d54fb487e816807c1d01075c33dc865c15ee74fc80df79f680bab.

The clusters come with `mc` installed and configured with a target
named `kostest` that refers to the above COS instance.

For each experiment there is a short ID.  We make a bucket having that
ID as its name.  At the end of each experiment, each node creates a
ZIP archive of all the node's data to save and stores that archive in
that bucket.
