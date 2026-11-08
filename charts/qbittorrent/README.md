# qBittorrent Helm Chart

This Helm chart installs qBittorrent, a torrent downloader, in a Kubernetes cluster.

This README covers the basics of customising and installation

![qBittorrent](./icon.png)

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
helm repo add mediar-servarr https://media-servarr.shw.al/charts

helm install qbittorrent media-servarr/qbittorrent
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/qbittorrent/`

Note that running a Wireguard client in kubernetes will require the chart to set the `net.ipv4.conf.all.src_valid_mark` sysctl for the deployment. You must use `allowed-unsafe-sysctls` on your kubelets to allow this in your kubernetes environment.

## Configuration

Here is some example of some configuration you may want to override and include in installation with `-f myvalues.yaml`

### Secrets

To set up secrets use the following format. Your Wireguard configuration may require the following items, which are all supported in the default chart config.

```yaml
secrets:
  - name: 'privatekey'
    value: ''
  - name: 'address'
    value: ''
  - name: 'publickey'
    value: ''
  - name: 'presharedkey'
    value: ''
  - name: 'endpoint'
    value: ''
  - name: 'dns'
    value: ''
```

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  # Main application web UI port
  port: 8080
  # Access url base
  urlBase: 'qbittorrent'
  # ConfigMap for core application settings
  config:
    # Filename of configuration
    filename: 'wg0.conf'
    # Configuration file contents
    contents: |
      [Interface]
      PrivateKey = $privatekey
      Address = $address
      DNS = $dns


      [Peer]
      PublicKey = $publickey
      PresharedKey = $presharedkey
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 0
      Endpoint = $endpoint
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by defing the config as null. For example;

```yaml
application:
  ...
  config: null
```

There are some environment variables that are required as well. These are set to the defaults below, but you may want to update these to suit your environment.

```yaml
    env:
      - name: 'QBT_LEGAL_NOTICE'
        value: 'confirm' # Do not change!
      - name: 'LAN_NETWORK'
        value: '10.42.0.0/16'
      - name: 'PGID'
        value: '1000'
      - name: 'PUID'
        value: '1000'
      - name: 'WEBUI_URL'
        value: 'http://media-servarr.local/qbittorrent'
      - name: 'WEBUI_USER'
        value: 'admin'
      - name: 'WEBUI_PASS'
        value: 'adminadmin'
```
More configuration options for the container are available at https://github.com/tenseiken/docker-qbittorrent-wireguard/wiki

You will also want to verify that the PUID and PGID are appropriate, and that `wg0` is the interface being used by Qbittorrent in "Settings > Advanced".

### Volumes

Two volumes are available by default:

- **config** - General config data, where the sqlite database exists, for example
- **downloads** - Downloads folder

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'qbittorrent-config'
    downloads:
      nfs:
        server: 'fileserver.local'
        path: '/downloads/'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for downloads unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  qbittorrent-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    selector:
      matchLabels:
        type: 'local'
```

Qbittorrent is configured to use '/downloads' as the location - you may need to adjust the application settings or path mapping to get this working with your *arr stack.

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

Metrics are not available for this chart.

```yaml
metrics:
  enabled: false
```

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

For advanced features of the underlying container, please see https://github.com/tenseiken/docker-qbittorrent-wireguard/wiki

### Kubernetes Network Security Concerns

You will likely need to disable IPv6 for the VPN settings to work. There are several "unsafe" sysctls you will want to allow in your kubernetes cluster; review the kubernetes documentation for your particular flavor. The necessary sysctls are set in the default chart values.

`allowed-unsafe-sysctls=net.ipv4.conf.all.src_valid_mark,net.ipv6.conf.all.disable_ipv6`

## Upgrading

To upgrade the deployment:

```bash
helm upgrade qbittorrent media-servarr/qbittorrent -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `qbittorrent` deployment:

```bash
helm uninstall qbittorrent
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
