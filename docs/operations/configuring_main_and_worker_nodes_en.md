# Configuring the Main and Worker Nodes

The main and worker nodes need to be configured to be fully accessible in your cluster. This document describes the
complete configuration options.

## Format of Configuration File

The worker and main nodes are configured by a JSON file that is mounted on every node
at `/etc/ces/nodeconfig/k3sConfig.json`. The json file has the following format:

**Example: k3sConfig.json**

```json
{
  "ces-main": {
    "isMainNode": true,
    "node-ip": "192.168.56.2",
    "node-external-ip": "192.168.56.2",
    "flannel-iface": "enp0s8"
  },
  "ces-worker-0": {
    "node-ip": "192.168.56.3",
    "node-external-ip": "192.168.56.3",
    "flannel-iface": "enp0s8"
  }
}
```

Each node gets an entry in this file. The identifier is chosen based on the host name of the node, e.g., our main node
has the host name `ces-main` and our worker node has the host name `ces-worker-0`. The nodes use their host name to
retrieve the configuration relevant for them.

## Configuration Options

This section describes the possible configuration option in detail:

**isMainNode**

```
Option:            isMainNode
Required: false
Description:       This flag decides whether a node is the main node.
Accepted Values:   true|false
Default Value:     false
```

**flannel-iface**

```
Option:            flannel-iface
Required:          true
Description:       This option contains the interface identifier used for k3s.
Accepted Values:   any valid interface name (ip a | grep ": ")
```

**node-ip**

```
Option:            node-ip
Required:          true
Description:       The IP of the node that is reachable via the specified flannel-iface.
Accepted Values:   Valid IPv4 Address (xxx.xxx.xxx.xxx)
```

**node-external-ip**

```
Option:            node-external-ip
Required:          true
Description:       The external IP of the node. Can be the same as the node-ip.
Accepted Values:   Valid IPv4 Address (xxx.xxx.xxx.xxx)
```

## Using the Node Configuration in the EcoSystem

It is especially important to mount the configuration file into all nodes at path `/etc/ces/nodeconfig/k3sConfig.json`
at startup. At startup a custom service is triggered to configure the `k3s` or `k3s-agent` service accordingly. 