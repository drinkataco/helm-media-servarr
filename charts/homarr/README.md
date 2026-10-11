# Homarr Helm Chart

This Helm chart installs Homarr, a server dashboard, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Homarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Secrets](#secrets)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install homarr media-servarr/homarr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/homarr/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Secrets

Homarr **will not start** without `SECRET_ENCRYPTION_KEY`. Until it is set the container fails its instrumentation hook with `Error: Invalid environment variables` and serves HTTP 500 on every path — including `/api/health`.

Generate one with `openssl rand -hex 32` (64 hex characters). Keep it: changing it invalidates everything Homarr has already encrypted.

No default is shipped on purpose — a shipped key would be shared by every deployment that forgot to change it.

Homarr is configured by environment variable rather than a config file, so the base chart cannot auto-inject the secret the way it does for the *arr charts. Two halves are needed — the `secrets` entry, and a matching reference in `env`:

```yaml
secrets:
  - name: 'SECRET_ENCRYPTION_KEY'
    value: 'your-64-hex-chars-here'
    # ref: 'my-existing-secret'   # or point at an existing Secret

deployment:
  container:
    env:
      - name: 'TZ'
        value: 'UTC'
      - name: 'SECRET_ENCRYPTION_KEY'
        valueFrom:
          secretKeyRef:
            # the Secret this chart creates: <release-name>-homarr
            name: 'homarr-homarr'
            key: 'SECRET_ENCRYPTION_KEY'
```

`env` is a list, so it replaces the chart's default wholesale — carry the `TZ` entry across if you want it.

Note that Homarr is not an LSIO image and does not honour `PUID`/`PGID`.

### Application Configuration

You can change the default port in the application config

```yaml
application:
  port: 7575
```

### Volumes

Three volumes are available by default:

- **app-data-configs** - Dashboard files
- **data** - Homarr data
- **app-data-icons** - Icons

```yaml
deployment:
  ...
  volumes:
    # Dashboard (config) files
    app-data-configs:
      persistentVolumeClaim:
        claimName: 'my-pv-claim1'
    # Dashboard Icons
    app-data-icons:
      # Example direct NFS mount without need for PV
      nfs:
        server: 'fileserver'
        path: '/srv/homarr/icons'
    # DB files — a PVC is provisioned by default (see below)
    data:
      persistentVolumeClaim:
        claimName: 'homarr-data'
```

By default a PersistentVolumeClaim is provisioned for `data`; `emptyDir: {}` is used for the other two unless overridden in your `values.yaml`.

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

## Uninstallation

To uninstall/delete the `homarr` deployment:

```bash
helm uninstall homarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
