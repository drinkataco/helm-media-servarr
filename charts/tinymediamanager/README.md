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
  * [Headless Usage](#headless-usage)
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
- **film** - Location of movies, mounted at `/media/film`
- **television** - Location of TV shows, mounted at `/media/tv`

tinyMediaManager refuses to add a folder at the root of the container filesystem (such as `/film`) as a data source, so media is mounted under `/media`.

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

### Headless Usage

The web UI is a full desktop session over noVNC, but routine tasks can be run without it.

**HTTP API** - enable it in *Settings > General > System > HTTP API* and set an API key. The chart already exposes it on the `api` port (`7878`), so it can be called from inside the cluster, for example from a CronJob:

```bash
curl -X POST http://tinymediamanager:7878/api/movie \
  -H 'Content-Type: application/json' \
  -H 'api-key: <your-api-key>' \
  -d '[{"action":"update","scope":{"name":"all"}},{"action":"scrape","scope":{"name":"new"}}]'
```

Use `/api/tvshow` for TV shows. See the [HTTP API docs](https://www.tinymediamanager.org/docs/http-api) for the available actions.

**Command line** - the `tinyMediaManager` binary accepts `movie` and `tvshow` commands, which can be run in the pod:

```bash
kubectl exec deploy/tinymediamanager -- /app/tinyMediaManager movie -u -n -r
```

See the [command line docs](https://www.tinymediamanager.org/docs/commandline) for all flags.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables and define a `serviceAccount`.

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

