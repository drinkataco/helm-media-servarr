# tinyMediaManager Helm Chart

This Helm chart installs tinyMediaManager, a media manager for movies and TV shows, in a Kubernetes cluster.

This README covers the basics of customising and installation

![tinyMediaManager](./icon.png)

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

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install tinymediamanager media-servarr/tinymediamanager
```

By default, this chart exposes tinyMediaManager at `http://tinymediamanager.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Application Configuration

A startup configuration is defined using a ConfigMap in `application.config`

```yaml
application:
  port: 4000
  config:
    filename: 'launcher-extra.yml'
    contents: |
      jvmOpts:
        - "-Xmx1024m"
    mountPath: '/app/launcher-extra.yml'
```

The chart exposes two container ports: `http` (`4000`, the web UI) and `api` (`7878`, the REST API used by companion apps). Both are declared in `deployment.container.ports` and exposed on the Service.

You can prevent a ConfigMap being created and the configuration being managed as a kubernetes resource by defining the config as null. For example:

```yaml
application:
  ...
  config: null
```

### Volumes

Three volumes are available by default:

- **data** - tinyMediaManager application data, logs, cache, and backups
- **film** - Location of movies
- **television** - Location of TV shows

```yaml
deployment:
  ...
  volumes:
    data:
      persistentVolumeClaim:
        claimName: 'tinymediamanager-data'
    film:
      nfs:
        server: 'fileserver.local'
        path: '/srv/media/film/'
    television:
      nfs:
        server: 'fileserver.local'
        path: '/srv/media/television/'
```

By default, a PersistentVolumeClaim will be provisioned for `data`, but `emptyDir: {}` will be used for film and television unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  tinymediamanager-data:
    accessMode: 'ReadWriteOnce'
    requestStorage: '20Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

tinyMediaManager is best exposed on a dedicated host at `/`, rather than under a shared path prefix. This chart therefore defaults to a dedicated host and a root path.

```yaml
ingress:
  enabled: true
  host: 'tinymediamanager.example.com'
  path: '/'
  tls:
    # Your TLS settings...
```

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables and define a `serviceAccount`. Note that tinyMediaManager reads `USER_ID`/`GROUP_ID` for the user it runs as — not the LSIO `PUID`/`PGID` the other charts in this collection use. Both are left unset by default so the image's own defaults own file ownership on the data volume; set them before first install rather than on an existing one.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade tinymediamanager media-servarr/tinymediamanager -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `tinymediamanager` deployment:

```bash
helm uninstall tinymediamanager
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.

