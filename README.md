# UnMango Charts

[![CI](https://github.com/unmango/charts/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/unmango/charts/actions/workflows/ci.yml)
[![Release](https://github.com/unmango/charts/actions/workflows/release.yml/badge.svg)](https://github.com/unmango/charts/actions/workflows/release.yml)
[![License](https://img.shields.io/github/license/unmango/charts)](./LICENSE)
[![Helm repo](https://img.shields.io/badge/helm-repo-0F1689?logo=helm&logoColor=white)](https://unmango.github.io/charts)
[![Built with Nix](https://img.shields.io/static/v1?label=Built%20with&message=Nix&color=5277C3&logo=nixos&logoColor=white&style=flat-square)](https://builtwithnix.org)
[![Last commit](https://img.shields.io/github/last-commit/unmango/charts)](https://github.com/unmango/charts/commits/main)
[![Hercules CI](https://hercules-ci.com/api/v1/site/github/account/unmango/project/charts/badge)](https://hercules-ci.com/github/unmango/charts)

Random Helm charts you may or may not find useful.
Use at your own risk.

## Usage

```sh
helm repo add unmango https://unmango.github.io/charts
helm install filebrowser unmango/filebrowser
```

Every chart is also published as an OCI artifact under `ghcr.io/unmango/charts`, with identical contents:

```sh
helm install filebrowser oci://ghcr.io/unmango/charts/filebrowser --version <version>
```

Each chart is its own repository, tagged only with released chart versions, so `--version` is required.
There is no `latest` tag.
The version table below links to the releases each tag corresponds to.

## Charts

| Chart | Upstream | Version | Status |
| --- | --- | --- | --- |
| [actions-runner](./charts/actions-runner/) | [unmango/containers](https://github.com/unmango/containers/tree/main/images/actions-runner) | [![actions-runner](https://img.shields.io/github/v/release/unmango/charts?filter=actions-runner-*&label=actions-runner)](https://github.com/unmango/charts/releases?q=actions-runner) | [Library chart](#actions-runner) |
| [deemix](./charts/deemix/) | [bambanah/deemix](https://github.com/bambanah/deemix) | [![deemix](https://img.shields.io/github/v/release/unmango/charts?filter=deemix-*&label=deemix)](https://github.com/unmango/charts/releases?q=deemix) | [Revived fork](#deemix) |
| [deluge](./charts/deluge/) | [linuxserver/docker-deluge](https://github.com/linuxserver/docker-deluge) | [![deluge](https://img.shields.io/github/v/release/unmango/charts?filter=deluge-*&label=deluge)](https://github.com/unmango/charts/releases?q=deluge) | [Active](#deluge-and-qbittorrent) |
| [filebrowser](./charts/filebrowser/) | [filebrowser/filebrowser](https://github.com/filebrowser/filebrowser) | [![filebrowser](https://img.shields.io/github/v/release/unmango/charts?filter=filebrowser-*&label=filebrowser)](https://github.com/unmango/charts/releases?q=filebrowser) | [Upstream archived](#filebrowser) |
| [gha-runner-scale-set](./charts/gha-runner-scale-set/) | [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller) | [![gha-runner-scale-set](https://img.shields.io/github/v/release/unmango/charts?filter=gha-runner-scale-set-*&label=gha-runner-scale-set)](https://github.com/unmango/charts/releases?q=gha-runner-scale-set) | [Patched fork](#gha-runner-scale-set) |
| [gluetun](./charts/gluetun/) | [qdm12/gluetun](https://github.com/qdm12/gluetun) | [![gluetun](https://img.shields.io/github/v/release/unmango/charts?filter=gluetun-*&label=gluetun)](https://github.com/unmango/charts/releases?q=gluetun) | [Library chart](#gluetun) |
| [hercules-ci-agent](./charts/hercules-ci-agent/) | [hercules-ci/hercules-ci-agent](https://github.com/hercules-ci/hercules-ci-agent) | [![hercules-ci-agent](https://img.shields.io/github/v/release/unmango/charts?filter=hercules-ci-agent-*&label=hercules-ci-agent)](https://github.com/unmango/charts/releases?q=hercules-ci-agent) | [Active](#hercules-ci-agent) |
| [mage-server](./charts/mage-server/) | [magefree/mage](https://github.com/magefree/mage) | [![mage-server](https://img.shields.io/github/v/release/unmango/charts?filter=mage-server-*&label=mage-server)](https://github.com/unmango/charts/releases?q=mage-server) | [Active](#xmage) |
| [qbittorrent](./charts/qbittorrent/) | [linuxserver/docker-qbittorrent](https://github.com/linuxserver/docker-qbittorrent) | [![qbittorrent](https://img.shields.io/github/v/release/unmango/charts?filter=qbittorrent-*&label=qbittorrent)](https://github.com/unmango/charts/releases?q=qbittorrent) | [Active](#deluge-and-qbittorrent) |
| [unifi](./charts/unifi/) | [linuxserver/docker-unifi-network-application](https://github.com/linuxserver/docker-unifi-network-application) | [![unifi](https://img.shields.io/github/v/release/unmango/charts?filter=unifi-*&label=unifi)](https://github.com/unmango/charts/releases?q=unifi) | [Active](#unifi) |

## Remarks

### actions-runner

Library chart, installs nothing.
Provides pod spec fragments (store volume, mount, `NIX_CONFIG`) for building with Nix.
Templates take the `nix` block as an argument, not `.Values`; see `charts/gha-runner-scale-set/values.yaml` for its shape.

### gluetun

Library chart, installs nothing.
Provides a gluetun VPN sidecar, a Private Internet Access config generator, and the pod DNS setting they need.
Its defaults land in the consumer under `gluetun`, so a consumer's users override them there; templates take that block plus the ports the firewall must admit.

- `pia.enabled` (default) needs `pia.existingSecret` with the PIA account. For any other provider, set `pia.enabled: false` and configure it through `env`.
- `firewall.outboundSubnets` is empty by default and must be set: the firewall covers the whole pod, so without the cluster's Service CIDR the workload cannot reach the cluster DNS Service and every lookup fails. Add the pod CIDR for direct pod traffic.
- gluetun runs as a native sidecar, so consumers need Kubernetes 1.29 or newer.

### gha-runner-scale-set

Upstream chart, patched to wire in a Nix store.
`templates/` and `values.yaml` are generated (`make chart-gha-runner-scale-set`); edit `patches/`, never the generated files.

- `nix.store.backing: hostPath` needs the node directory pre-created and writable; prefer `existingClaim` unless you need a shared warm store.
- Never `backing: none` for a runner that builds (overlayfs breaks nix's build-dir teardown).
- Never share one store via `ReadWriteMany` (SQLite + flock corrupts over NFS/CephFS).
- Set `nix.maxJobs`/`nix.cores` explicitly, nix ignores cgroup CPU limits and defaults to 1 job.
- `containerMode: kubernetes-novolume` mounts nothing; not for a runner that builds.
- Keeps upstream's `labels` helper, since the controller keys on `app.kubernetes.io/name`.

### Hercules CI Agent

No upstream image or chart; uses `unmango/containers`.

- Set `clusterJoinToken` or `existingSecret` (`cluster-join-token.key`, `binary-caches.json`, `secrets.json`); rotating `existingSecret` needs a manual pod restart.
- Chart overrides the image's broken `SSL_CERT_FILE`/`NIX_SSL_CERT_FILE` paths.
- No `/nix/var/nix`; Nix chroots into the persistent volume, so `persistence.size` defaults to `100Gi` and losing the volume also loses the agent's session key.
- `effects.enabled: true` runs the pod privileged.
- Excluded from `ct install`: without a real join token it never reaches Ready.

### XMage

No upstream image; uses `xmage-docker`.
`server.*` values map to `XMAGE_*` env vars; `existingConfigMap` bypasses that mapping entirely.

- Raw TCP on `17171`/`17179`, no Ingress/HTTPRoute, expose via LoadBalancer, NodePort, or TCPRoute.
- `server.secondaryBindPort` must be a fixed port (not `-1`).
- First start takes minutes to load the card database; readiness probe allows 10 minutes.
- Runs as root; capabilities are dropped but `runAsNonRoot` is not set.

### UniFi

Uses the linuxserver image, which needs a separate MongoDB service; the chart deploys one or connects to yours through `database.host`.

- `mongodb.enabled: true` (default) deploys `mongo:8.0` beside the controller; set it `false` and fill `database.host` to use your own.
- MongoDB 8.0 is the newest the controller supports; Renovate holds the bundled image below 8.1.
- Passwords are generated and kept across upgrades unless set; `database.existingSecret` needs `mongodb-password`, plus `mongodb-root-password` with the bundled MongoDB.
- The init script creates the controller user only on an empty data directory; changing `database.*` later does not alter it.
- Devices need `inform` (TCP 8080) and `stun` (UDP 3478) on the Service; discovery does not cross subnets, so devices elsewhere need `set-inform`.
- The UI serves a self-signed certificate on 8443, so there is no Ingress or HTTPRoute.
- `mongodb.tls.enabled` serves TLS from a secret holding the certificate and its key in one PEM file, the layout cert-manager's `CombinedPEM` output format writes; `database.tls` points the controller at it and is first-run-only, like the rest of `database.*`.
- The controller validates that certificate against the JVM truststore, so a privately issued one needs `truststore.existingConfigMap` or `truststore.existingSecret` holding a PKCS12 truststore. It replaces the JVM's own, so keep the public CAs in it.

### Filebrowser

Upstream is archived (2026-09-01), no further releases or fixes.
The chart still works against the final image.

### Deemix

Upstream (RemixDev) is abandoned.
The chart deploys the maintained fork at [bambanah/deemix](https://github.com/bambanah/deemix).

### Deluge and qBittorrent

linuxserver images behind the `gluetun` library's VPN sidecar.

- `gluetun.pia.existingSecret` is required unless `gluetun.enabled` is false.
- The pod is Ready only once the tunnel is up.
- qBittorrent: `auth.password` or `auth.existingSecret` is written into `qBittorrent.conf` as a PBKDF2 hash on every start; without either, the log shows a temporary password.
- Deluge: `torrentPort` must match the incoming port in Deluge's preferences, since the image does not read it from the environment. The WebUI starts with the password `deluge`.
