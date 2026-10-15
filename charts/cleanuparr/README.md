# Cleanuparr Helm Chart

This Helm chart installs Cleanuparr, a companion application for [Radarr](../radarr/), [Lidarr](../lidarr/), and [Sonarr](../sonarr/) to manage unwanted or blocked files.

This README covers the basics of customising and installation

![Cleanuparr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Secrets](#secrets)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Metrics](#metrics)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install cleanuparr media-servarr/cleanuparr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/cleanuparr/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Secrets

Cleanuparr defines `apiKey` by default, and you can optionally define integration keys such as `sonarrApiKey` and `radarrApiKey`.

You can either define secret values directly in your chart values, or reference keys from an existing Secret.

```yaml
secrets:
  # inline value
  - name: 'apiKey'
    value: 'your-api-key-here'

  # reference pre-existing Secret
  - name: 'sonarrApiKey'
    ref: 'sonarr-api-secret'
  - name: 'radarrApiKey'
    ref: 'radarr-api-secret'
```

When `ref` is set, the chart reads key `name` from the Secret named by `ref` in the same namespace.

### Application Configuration

Application configuration is managed via the GUI and stored in the application database.

### Volumes

Two volumes are included:

- **config** - General config data, where the sqlite database exists, for example
- **downloads** - Mounted at `/downloads`, the directory Cleanuparr prunes

Cleanuparr removes failed and orphaned downloads, so `downloads` needs to be the same volume your download client writes to. It defaults to an `emptyDir`, which gives Cleanuparr nothing to clean — point it at that volume:

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        claimName: 'cleanuparr-config'
    downloads:
      persistentVolumeClaim:
        claimName: 'media-downloads'
```

By default, a PersistentVolumeClaim will be provisioned for the `config` named `cleanuparr-config`.

```yaml
persistentVolumeClaims:
  cleanuparr-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

Ingress can be enabled, and you can customise the default host, path, and TLS settings:

```yaml
ingress:
  enabled: true
  host: 'example.com'
  tls:
    # Your TLS settings...
```

### Metrics

Metrics are not supported for this application.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade cleanuparr media-servarr/cleanuparr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `cleanuparr` deployment:

```bash
helm uninstall cleanuparr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
