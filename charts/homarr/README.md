# Homarr Helm Chart

This Helm chart installs Homarr, a server dashboard, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Homarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Homarr requires a `SECRET_ENCRYPTION_KEY` of 64 hex characters, read from a Secret this chart does not create. Create it first, in the release's namespace:

```bash
kubectl create secret generic homarr-encryption-key \
  --from-literal=secretEncryptionKey="$(openssl rand -hex 32)"
```

Keep the key safe: changing it makes the integration credentials already stored in Homarr unreadable.

Then install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install homarr media-servarr/homarr
```

Pointing the host `homarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://homarr.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Application Configuration

You can change the default port in the application config

```yaml
application:
  port: 7575
```

### Volumes

One volume is available by default:

- **data** - Homarr data (`/appdata`): the SQLite database, Redis dump and trusted certificates

```yaml
deployment:
  ...
  volumes:
    data:
      persistentVolumeClaim:
        claimName: 'my-pv-claim'
```

By default a PersistentVolumeClaim is provisioned for `data`.

```yaml
persistentVolumeClaims:
  # Default PV is for 'data' where the SQlite database exists
  data:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

Ingress is enabled by default and Homarr is served from the root path (`/`). Override host and TLS as needed:

```yaml
ingress:
  enabled: true
  host: 'example.com'
  path: '/'
  tls:
    # Your TLS settings...
```

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade homarr media-servarr/homarr -f myvalues.yaml
```

### 1.0.0

Chart 1.0.0 moves to Homarr v2. Before upgrading:

- Create the `homarr-encryption-key` Secret described in [Installation](#installation) if you have not already set `SECRET_ENCRYPTION_KEY` yourself.
- The `data` volume is now mounted at `/appdata`, where Homarr keeps its database. Earlier chart versions mounted it at `/data`, so data was written to the container filesystem and not kept across restarts.
- The `app-data-configs` and `app-data-icons` volumes have been removed; Homarr no longer reads those paths. Drop any overrides for them.
- MySQL is no longer supported by Homarr v2. Convert to SQLite with Homarr's converter before upgrading.

## Uninstallation

To uninstall/delete the `homarr` deployment:

```bash
helm uninstall homarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
