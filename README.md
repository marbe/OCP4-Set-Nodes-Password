# OCP4 Set Nodes Password

For internal security standard a customer asks for a solution to disable SSH access to OpenShift nodes with key and to enable access with a password.

## Target version

Version 1.0.0 of this repo has been tested on **OpenShift 4.6.15**. Please consider that there is a [bug](https://bugzilla.redhat.com/show_bug.cgi?id=1885186) related to clearing OCP nodes `authorized_keys` file.

This bug is also documented in this solution:

 * [Removing SSH key machine configs does not prevent login with private key](https://access.redhat.com/solutions/5463711)

## How to disable SSH access with key

 * delete default ssh machineconfig:

```
oc delete mc 99-worker-ssh
oc delete mc 99-master-ssh
```

 * create new machineconfig with empty `authorized_keys` file:

```
oc create -f 99-master-ssh-empty.yaml
oc create -f 99-worker-ssh-empty.yaml
```

 * monitor machineconfig update up to completion (*)

## How to enable password authentication for 'core' user and set it

### Pre-requisites

`curl` and `oc` command must be present and in the PATH of the user that run the script.

### SSHD configuration

 * Apply machineconfig to modify the configuratio of `/etc/sysconfig/sshd` and `/etc/ssh/sshd_config`:

```
oc create -f 50-master-sysconfig-sshd.yaml && oc create -f 50-master-sshd-password.yaml
oc create -f 50-master-sysconfig-sshd.yaml && oc create -f 50-master-sshd-password.yaml
```

 * monitor machineconfig update up to completion (*)

 * run `ocp4-set-nodes-password.sh` script on all nodes(**)

```
./ocp4-set-nodes-password.sh -c <clustername>.<basedomain>
```

**WARINING: If a node hangs, simply press CTRL+C to skip it and shift to the next node**

## How to test previous steps on a single node

In order to test this solution on a single node, it is possible to:

 * create a machineconfigpool named 'single':

```
oc create -f single-mcp.yaml
```

 * label a node with 'single' role:

```
oc label node <nodename> node-role.kubernetes.io/single=""
```

 * apply specific 'single' machineconfig in previous steps instead of 'worker' and 'master' ones:


```
oc create -f 99-single-ssh-empty.yaml
oc create -f 50-single-sysconfig-sshd.yaml && oc create -f 50-single-sshd-password.yaml
```

 * run `ocp4-set-nodes-password.sh` script with `-l` option and specify the proper label:

```
./ocp4-set-nodes-password.sh -c <clustername>.<basedomain> -l node-role.kubernetes.io/single
```

---

(*)

```
watch -n1 'oc get node -o "custom-columns=NAME:metadata.name,STATE:metadata.annotations.machineconfiguration\\.openshift\\.io/state,DESIRED:metadata.annotations.machineconfiguration\\.openshift\\.io/desiredConfig,CURRENT:metadata.annotations.machineconfiguration\\.openshift\\.io/currentConfig,REASON:metadata.annotations.machineconfiguration\\.openshift\\.io/reason"'
```

---

(**)

```
$ ./ocp4-set-nodes-password.sh

ocp4-set-nodes-password.sh:
Changes the 'core' user login password for each OCP4 node of the provided cluster.

Syntax: ocp4-set-nodes-password.sh [-h|V] [-l label] -c <clustername.basedomain>
options:
-h                             Print this Help.
-V                             Print software version and exit.
-l label                       Change password for nodes with this label.
-c <clustername.basedomain>    Specify the Cluster name to work on.
```
