# Configuring the Main and Worker Nodes

The main and worker nodes need to be configured to be fully accessible in your cluster. This document describes the
complete configuration options.

## Format of Configuration File

The worker and main nodes are configured by a JSON file that has to be mounted on every node
at `/etc/ces/nodeconfig/k3sConfig.json`. The json file has the following format:

**Example: k3sConfig.json**

```json
{
  "docker-registry-configuration": {
    "mirrors": {
      "docker.io": {
        "endpoint": [
          "https://192.168.179.19",
          "https://192.168.179.20"
        ]
      },
      "registry.cloudogu.com": {
        "endpoint": [
          "https://192.168.179.19"
        ]
      }
    },
    "configs": {
      "192.168.179.19": {
        "auth": {
          "username": "ces-admin",
          "password": "ces-admin"
        },
        "tls": {
          "cert_file": "path to the cert file used in the registry",
          "key_file":  "path to the key file used in the registry",
          "ca_file": "path to the ca file used in the registry",
          "insecure_skip_verify": false
        }
      },
      "192.168.179.20": {
        "auth": {
          "token": "token"
        }
      }
    }
  }
}
```

Each node gets an entry in this file. To find out the right configuration, the nodes
try to match their host name with the `name` field of every `nodes` object.

## CES Namespace

The entry `ces-namespace` lets you specify which kubernetes namespace the CES is installed into.

## k3s Token

The entry `k3s-token` lets you specify the token the nodes will use to authenticate inside the cluster.
This token can not be changed once the cluser has been installed.

## Node Configuration Options

This section describes the possible configuration options in detail:

## docker-registry-configuration

The `docker-registry-configuration` entry allows you to configure private Docker registries for k3s.
Mirrors for specific registries can be specified. Each mirror can be configured using the `configs` object.
The `docker-registry-configuration` is stored on the node (main and worker) under `/etc/rancher/k3s/` directory.

**name**

```
Option:            name
Required:          true
Description:       This option contains the node's (host) name.
Accepted Values:   Any valid host name
```

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
### docker-registry-configuration
This section describes the possible configuration options for the `docker-registry-configuration` in detail:

The configuration options map, the options for the `registries.yaml` for k3s from Rancher.
These can be found [here](https://docs.k3s.io/installation/private-registry).

A complete configuration could look like the following:

```json
{
  "docker-registry-configuration": {
    "mirrors": {
      "docker.io": {
        "endpoint": [
          "https://192.168.179.19",
          "https://192.168.179.20"
        ]
      },
      "registry.cloudogu.com": {
        "endpoint": [
          "https://192.168.179.19"
        ]
      }
    }
  },
  "configs": {
    "192.168.179.19": {
      "auth": {
        "username": "ces-admin",
        "password": "ces-admin"
      },
      "tls": {
        "cert_file": "path to the cert file used in the registry",
        "key_file":  "path to the key file used in the registry",
        "ca_file": "path to the ca file used in the registry",
        "insecure_skip_verify": false
      }
    },
    "192.168.179.20": {
      "auth": {
        "token": "token"
      }
    }
  }
}
```

## Using the Node Configuration in the EcoSystem

It is especially important to mount the configuration file into all nodes at path `/etc/ces/nodeconfig/k3sConfig.json`
at startup. At startup a custom service is triggered to configure the `k3s` or `k3s-agent` service accordingly. 