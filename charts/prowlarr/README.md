# Prowlarr Helm Chart

This Helm chart installs Prowlarr, an indexer manager, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Prowlarr](./icon.png)

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

helm install prowlarr media-servarr/prowlarr
```

Pointing the host `prowlarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://prowlarr.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Secrets

To set up secrets, like API keys, use the following format. Use `openssl rand -hex 16` to generate a key and replace the default value.

```yaml
secrets:
  # inline value
  - name: 'apiKey'
    value: 'your-api-key-here'
  # reference pre-existing Secret
  # - name: 'apiKey'
  #   ref: 'my-existing-secret'
```
When `ref` is set, the chart reads key `name` from the Secret named by `ref` in the same namespace.

By not setting this value, and leaving it blank, prowlarr will automatically generate a key on start.

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  port: 9696 # default UI port
  config:
    filename: 'config.xml'
    contents: |
      <Config>
        ...
        <ApiKey>$apiKey</ApiKey>
        <Port>9696</Port>
        ...
      </Config>
    secrets: [ 'apiKey' ]
    mountPath: '/config/config.xml'
```

You can prevent a ConfigMap being created and the configuration being managed as a kubernetes resource by defining the config as null. For example:

```yaml
application:
  ...
  config: null
```

### Volumes

Only one volume is mounted by default:

- **config** — General config data, where the sqlite database lives

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        claimName: 'prowlarr-config'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`.

```yaml
persistentVolumeClaims:
  prowlarr-config:
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

Enabling metrics enables a sidecar container being attached for [exportarr](https://github.com/onedr0p/exportarr/) - and a ServiceMonitor CRD to be consumed by the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) package.

By default, Exportarr reads the `apiKey` from this chart's Secret. If you need Exportarr to read a different Secret/key, set `metrics.apiref`.

```yaml
metrics:
  enabled: true
  apiref:
    secret: 'my-existing-secret'
    keyname: 'apiKey'
  env:
    - name: 'PROWLARR__BACKFILL'
      value: 'true'
    - name: 'PROWLARR__BACKFILL_SINCE_DATE'
      value: '1970-01-01'
```

It is recommended to install [kube-prometheus chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) first for the CRD to be supported. It is not included as a dependency by default in this package!

Unless changed with `metrics.port.number` you can then consume metrics over port `9703`.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade prowlarr media-servarr/prowlarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `prowlarr` deployment:

```bash
helm uninstall prowlarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
