# Transmission Helm Chart

This Helm chart installs Transmission, a bittorrent download client, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Transmission](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Secrets](#secrets)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Service](#service)
  * [Ingress](#ingress)
  * [VPN Sidecar](#vpn-sidecar)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install transmission media-servarr/transmission
```

Pointing the host `transmission.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://transmission.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Secrets

You can either define secret values directly in your chart values, or reference keys from an existing Secret.

```yaml
secrets:
  # inline value
  - name: 'rpcPassword'
    value: 'password'

  # reference pre-existing Secret
  # - name: 'rpcPassword'
  #   ref: 'my-existing-secret'
```

When `ref` is set, the chart reads key `name` from the Secret named by `ref` in the same namespace.

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  port: 9091 # default UI port
  config:
    filename: 'settings.json'
    contents: |
      {
        ...
        "rpcAuthentication": true,
        "rpcUsername": "username",
        ...
      }
    secrets: [ 'rpcPassword' ]
    mountPath: '/config/settings.json'
```

You can prevent a ConfigMap being created and the configuration being managed as a kubernetes resource by defining the config as null. For example:

```yaml
application:
  ...
  config: null
```

### Volumes

Two volumes are used by default:

- **config** — General config data, where settings live
- **downloads** — Downloads folder

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        claimName: 'transmission-config'
    downloads:
      nfs:
        server: 'fileserver.local'
        path: '/srv/downloads/'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for downloads, unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  transmission-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Service

This chart defaults `service.type` to `LoadBalancer` (unlike the other charts, which default to `ClusterIP`). This is so the BitTorrent peer port can be reached externally, not just the RPC UI. If your cluster doesn't have a `LoadBalancer` provider (e.g. MetalLB, a cloud LB), change it to `NodePort` or `ClusterIP`:

```yaml
service:
  type: 'NodePort'
  # externalTrafficPolicy: 'Local'   # optional; preserves client source IP for NodePort/LoadBalancer
```

### Ingress

Ingress is disabled by default and typically not needed since the RPC UI is exposed through the LoadBalancer Service. If you want ingress for the UI, enable it and set host/TLS:

```yaml
ingress:
  enabled: true
  host: 'example.com'
  tls:
    # Your TLS settings...
```

### VPN Sidecar

Thanks to [qdm12/gluetun](https://github.com/qdm12/gluetun), it is fairly trivial to route traffic through a VPN.

[To see how, view the VPN docs.](./docs/vpn.md)

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade transmission media-servarr/transmission -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `transmission` deployment:

```bash
helm uninstall transmission
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
