# Flaresolverr Helm Chart

This Helm chart installs Flaresolverr, a proxy server to bypass Cloudflare and DDoS-GUARD protection.

This README covers the basics of customising and installation

![Flaresolverr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Access](#access)
  * [Usage](#usage)
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

helm install flaresolverr media-servarr/flaresolverr
```

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

Unlike other charts in this collection, configuration options are a lot more limited due to the nature of this application.

It is recommend you read the application documentation regarding [environment variables](https://github.com/FlareSolverr/FlareSolverr#environment-variables). This is how configuration is applied.

### Access

By default, the application can be accessed over port `8191`.

### Usage

This application is useful alongside [prowlarr](../prowlarr), allowing you to access certain torrent providers that are protected behind cloudflare. See [this guide](https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/) for information how to set this up.

By default, the internal URL will be `http://flaresolverr.{namespace}.svc.cluster.local:8191`

### Ingress

Flaresolverr is consumed in-cluster (by Prowlarr etc.) rather than externally and has no UI of its own, so ingress is **disabled by default** — unlike the other charts here. Enable it, and override host and TLS, only if you have a reason to reach it from outside the cluster:

```yaml
ingress:
  enabled: true
  host: 'example.com'
  tls:
    # Your TLS settings...
```

### Metrics

Flaresolverr exposes Prometheus metrics natively (not via Exportarr). Enable it by setting the following environment variables on the container:

```yaml
deployment:
  ...
  env:
    - name: 'PROMETHEUS_ENABLED'
      value: '1'
    - name: 'PROMETHEUS_PORT'
      value: '9702'
```

Metrics are then available on port `9702` (or whatever `PROMETHEUS_PORT` you set). To have Prometheus scrape them, install the [kube-prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) chart first and add a `ServiceMonitor` for this Service.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade flaresolverr media-servarr/flaresolverr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `flaresolverr` deployment:

```bash
helm uninstall flaresolverr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
