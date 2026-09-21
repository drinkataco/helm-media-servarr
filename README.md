# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml)
[![App Update](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml)


[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/media-servarr)](https://artifacthub.io/packages/search?repo=media-servarr)

![media-servarr](./icon.png)

A collection of Helm charts for self-hosted media - primarily built around the [Servarr](https://wiki.servarr.com/) family of charts, with some complementary charts here and there.

All charts share the common base (`media-servarr-base`) so configuration patterns are consistent across every application.

* [The Charts](#the-charts)
* [Prerequisites](#prerequisites)
* [Usage](#usage)
* [Configuration](#configuration)

## The Charts

| Chart | Description |
|---|---|
| [`bazarr`](./charts/bazarr) | Automatic subtitle downloader; companion to Sonarr and Radarr — [bazarr.media](https://www.bazarr.media/) |
| [`cleanuparr`](./charts/cleanuparr) | Removes stalled, orphaned, and unwanted items from download clients — [cleanuparr.github.io](https://cleanuparr.github.io/Cleanuparr/) |
| [`flaresolverr`](./charts/flaresolverr) | Proxy to bypass Cloudflare protection; used by Prowlarr — [github.com/FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) |
| [`homarr`](./charts/homarr) | Dashboard for self-hosted services — [homarr.dev](https://homarr.dev/) |
| [`jellyfin`](./charts/jellyfin) | Open-source media server for movies, TV, and music — [jellyfin.org](https://jellyfin.org/) |
| [`lidarr`](./charts/lidarr) | Music library manager — [lidarr.audio](https://lidarr.audio/) |
| [`profilarr`](./charts/profilarr) | Quality profile and custom format manager for the *arr stack — [github.com/Dictionarry-Hub/profilarr](https://github.com/Dictionarry-Hub/profilarr) |
| [`prowlarr`](./charts/prowlarr) | Indexer manager and proxy for the *arr stack — [prowlarr.com](https://prowlarr.com/) |
| [`radarr`](./charts/radarr) | Movie library manager — [radarr.video](https://radarr.video/) |
| [`readarr`](./charts/readarr) _(deprecated)_ | Book library manager — [readarr.com](https://readarr.com/) |
| [`sabnzbd`](./charts/sabnzbd) | Usenet download client — [sabnzbd.org](https://sabnzbd.org/) |
| [`sonarr`](./charts/sonarr) | TV series library manager — [sonarr.tv](https://sonarr.tv/) |
| [`tinymediamanager`](./charts/tinymediamanager) | Media metadata scraper and manager — [tinymediamanager.org](https://www.tinymediamanager.org/) |
| [`transmission`](./charts/transmission) | BitTorrent download client — [transmissionbt.com](https://transmissionbt.com) |

Each chart has its own `README.md` under [`./charts/<name>/`](./charts) with per-app installation and configuration details.

## Prerequisites

- Kubernetes `>=1.24`
- [Helm](https://helm.sh/) `>=3.12`
- (Optional) [Prometheus Operator](https://github.com/prometheus-operator/kube-prometheus) CRDs if enabling `metrics` where available (see [exportarr](https://github.com/onedr0p/exportarr))

## Usage

Add the Helm repository:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts
helm repo update
```

List available charts:

```bash
helm search repo media-servarr
```

Install a chart (Sonarr as an example):

```bash
helm install sonarr media-servarr/sonarr -f my-values.yaml
```

Upgrade an existing release:

```bash
helm upgrade sonarr media-servarr/sonarr -f my-values.yaml
```

## Configuration

The `media-servarr-base` library gives every chart the same building blocks: secret injection (inline or by reference), config-as-code via a ConfigMap-mounted config file, declarative PersistentVolumeClaims (including binding to a pre-existing PV via `volumeName`), ingress with optional TLS, an optional [Exportarr](https://github.com/onedr0p/exportarr) metrics sidecar for the *arr apps, and the usual pod-scheduling knobs.

For the full list of value keys, their types, and inline documentation:

- **Per-chart guides** — each chart has its own [`README.md`](./charts) with an installation walkthrough and worked examples.
- **JSON Schema** — [`values.schema.json`](./values.schema.json) validates every value path. Editors with the [YAML Language Server](https://github.com/redhat-developer/yaml-language-server) pick it up automatically via the modeline at the top of each `values.yaml`.
- **Default values** — [`values.yaml`](./values.yaml) is the canonical reference for defaults and shape.

A distinctive pattern used in these charts is the **config-as-code with secret substitution**: application config lives in `values.yaml`, gets rendered to a ConfigMap, and secrets are substituted at pod start, allowing use to use secrets and configmap without having to commit their values:

```yaml
secrets:
  - name: apiKey
    ref: 'my-api-key'

application:
  config:
    filename: config.xml
    mountPath: /config/config.xml
    secrets: [apiKey]        # substituted as $apiKey in contents
    contents: |
      <Config>
        <ApiKey>$apiKey</ApiKey>
      </Config>
```

### Deployment vs StatefulSet

Every chart defaults to running as a `Deployment` with the `Recreate` update strategy — the old pod terminates before the new one starts, so `ReadWriteOnce` config volumes don't hit `Multi-Attach` errors on upgrade. For single-replica apps this behaves identically to a StatefulSet with `OnDelete` at runtime.

For a semantically correct fit with the stateful apps (arr apps, jellyfin, sabnzbd, transmission, profilarr, tinymediamanager, homarr), the base chart also supports rendering a `StatefulSet` plus a headless service. Opt in per install via values:

```yaml
deployment:
  kind: 'StatefulSet'   # default: 'Deployment'
  updateStrategy:
    type: 'OnDelete'    # default when kind: StatefulSet
```

Flip only for fresh installs. Kubernetes doesn't allow in-place mutation of a resource's `kind`, so switching an existing install is a manual `helm delete <release>` followed by `helm install <release> ...` with the new values. PVCs survive the delete as long as you don't pass `--delete-persistent-volume-claims`, so data stays intact. `flaresolverr` is genuinely stateless and should stay a Deployment.
