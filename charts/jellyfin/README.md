# Jellyfin Helm Chart

This Helm chart installs Jellyfin, a web media system, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Jellyfin](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
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

helm install jellyfin media-servarr/jellyfin
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/jellyfin/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

Jellyfin has multiple config files which we can create ConfigMaps for. By default, we manage network.xml and system.xml, but we could also add encoding.xml.

```yaml
application:
  port: 8096 # default UI port
  urlBase: 'jellyfin' # default web base path
  config:
    - filename: 'network.xml'
      contents: |
        # We could change the BaseURL or Port here
        ...
      mountPath: '/config/config/network.xml'
    # System Options
    - filename: 'system.xml'
      contents: |
        # We could add <EnableMetrics>true</EnableMetrics> to enable prometheus metrics
        # It is recommended to add <IsStartupWizardCompleted>true</IsStartupWizardCompleted> to
        #  prevent the wizard running again after initial setup.
        ...
      mountPath: '/config/config/system.xml'
    - filename: 'encoding.xml'
      contents: |
        ...
      mountPath: '/config/config/encoding.xml'
```

You can prevent a ConfigMap being created and the configuration being managed as a kubernetes resource by defining the config as null. For example:

```yaml
application:
  ...
  config: null
```

### Volumes

The following volumes are available by default:

- **config** - General config data, where the sqlite database exists, for example
- **ebooks** - Location of ebooks
- **film** - Location of movies
- **music** - Location of music
- **television** - Location of TV shows

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        claimName: 'jellyfin-config'
    ebooks:
      nfs:
        server: 'fileserver.local'
        path: '/srv/media/ebooks/'
    film:
    music:
    television:
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for ebooks, film, music, and television, unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  jellyfin-config:
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

Prometheus metrics are enabled by placing `<EnableMetrics>true</EnableMetrics>` in System.xml.

Read more about this functionality in the [official documentation](https://jellyfin.org/docs/general/networking/monitoring/)

### Hardware Acceleration for Transcoding

If your cluster supports GPUs, you can use `runtimeClassName` to ensure you are using the correct runtime class, be sure `nodeSelector` to control app placement. You should review the [official documentation](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/) to understand how the official docker image supports hardware acceleration for your hardware type, and review the docs for enabling hardware passthrough on your kubernetes cluster.

### DLNA and Device Discovery

Jellyfin advertises its DLNA server over SSDP multicast, which does not cross the pod network boundary. If you want DLNA clients to discover the server automatically, run the pod on the host network:

```yaml
deployment:
  hostNetwork: true
  dnsPolicy: 'ClusterFirstWithHostNet'
```

Setting `dnsPolicy` matters here: with `hostNetwork: true` and Kubernetes' default `ClusterFirst` policy the pod inherits the node's resolver and loses in-cluster DNS. Note that host networking also binds the application port directly on the node, so only one such pod can be scheduled per node. See the [official documentation](https://jellyfin.org/docs/general/networking/dlna/) for the DLNA settings themselves.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade jellyfin media-servarr/jellyfin -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `jellyfin` deployment:

```bash
helm uninstall jellyfin
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
