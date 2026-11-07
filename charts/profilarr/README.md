# Profilarr Helm Chart

This Helm chart installs Profilarr, a configuration management platform for Radarr and Sonarr, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Profilarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Application Configuration](#application-configuration)
  * [Authentication](#authentication)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Parser Sidecar (optional)](#parser-sidecar-optional)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install profilarr media-servarr/profilarr
```

By default, this chart exposes Profilarr at `http://profilarr.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Application Configuration

Profilarr is configured primarily through environment variables. The upstream quick-start only requires a `/config` volume and port `6868`.

```yaml
application:
  port: 6868

deployment:
  container:
    env:
      - name: 'TZ'
        value: 'UTC'
```

### Authentication

Profilarr v2 supports two auth modes via the `AUTH` env var:

- `on` (default) — login required, using password auth managed inside Profilarr and/or OpenID Connect SSO.
- `off` — no auth. Only use on trusted networks or behind a proxy that authenticates for you.

`AUTH=oidc` is a deprecated alias for `on` as of Profilarr 2.3.0.

To enable SSO, keep `AUTH=on`, provide all three OIDC vars (`OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_DISCOVERY_URL`), and set `ORIGIN` to your public URL. Password and SSO login can be used together. Profilarr expects the redirect URL at `{ORIGIN}/auth/oidc/callback` — most IdPs infer this automatically.

Because `OIDC_CLIENT_SECRET` is sensitive, define it in the chart's `secrets:` block (or point at an existing Kubernetes Secret via `ref`) and bind it in `deployment.container.env` with `valueFrom.secretKeyRef`. Commented examples for both are in the chart's default `values.yaml`.

You can also set `PROFILARR_API_KEY` (min 32 characters) the same way. It is used for `X-Api-Key` auth, always has full access, works alongside any keys created in Settings > Security, and is not persisted to SQLite.

### Volumes

One volume is available by default:

- **config** - Profilarr configuration, database, and git working data

```yaml
deployment:
  ...
  volumes:
    config:
      persistentVolumeClaim:
        claimName: 'profilarr-config'
```

By default, a PersistentVolumeClaim will be provisioned for `config` unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  profilarr-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '5Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

Profilarr is best exposed on a dedicated host at `/`, rather than under a shared path prefix. Upstream still has an open request for custom host/port binding support, so this chart defaults to a dedicated host and root path.

```yaml
ingress:
  enabled: true
  host: 'profilarr.example.com'
  path: '/'
  tls:
    # Your TLS settings...
```

### Parser Sidecar (optional)

Custom-format and quality-profile *testing* — the screens where Profilarr checks a release name against your formats or simulates how a profile would score a release — is powered by a separate C# service that mirrors Radarr/Sonarr's own parsing logic. Every other feature (linking databases, building profiles, syncing to your arr instances, upgrade automation, notifications) works without it.

To enable, run the parser as a sidecar in the same Pod, listening on port `5000`:

```yaml
deployment:
  sideCarContainers:
    - name: 'parser'
      image: 'ghcr.io/dictionarry-hub/profilarr-parser:2.3.1'
      ports:
        - containerPort: 5000
          name: 'parser'
          protocol: 'TCP'
```

Pin the parser tag to the same version as Profilarr — they release together. Because the sidecar shares the Pod network, Profilarr reaches it on `localhost:5000` (its default), so no extra `PARSER_HOST` / `PARSER_PORT` env vars are needed.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables, and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade profilarr media-servarr/profilarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `profilarr` deployment:

```bash
helm uninstall profilarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.

