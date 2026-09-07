# UnMango Charts

[![CI](https://github.com/unmango/charts/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/unmango/charts/actions/workflows/ci.yml)
[![Release](https://github.com/unmango/charts/actions/workflows/release.yml/badge.svg)](https://github.com/unmango/charts/actions/workflows/release.yml)
[![License](https://img.shields.io/github/license/unmango/charts)](./LICENSE)
[![Helm repo](https://img.shields.io/badge/helm-repo-0F1689?logo=helm&logoColor=white)](https://unmango.github.io/charts)
[![Built with Nix](https://img.shields.io/static/v1?label=Built%20with&message=Nix&color=5277C3&logo=nixos&logoColor=white&style=flat-square)](https://builtwithnix.org)
[![Last commit](https://img.shields.io/github/last-commit/unmango/actions)](https://github.com/unmango/actions/commits/main)

Random Helm charts you may or may not find useful.
Use at your own risk.

## Usage

```sh
helm repo add unmango https://unmango.github.io/charts
helm install filebrowser unmango/filebrowser
```

## Charts

| Chart | Upstream | Version | Status |
| --- | --- | --- | --- |
| [actions-runner](./charts/actions-runner/) | [unmango/containers](https://github.com/unmango/containers/tree/main/images/actions-runner) | [![actions-runner](https://img.shields.io/github/v/release/unmango/charts?filter=actions-runner-*&label=actions-runner)](https://github.com/unmango/charts/releases?q=actions-runner) | Library chart |
| [deemix](./charts/deemix/) | [bambanah/deemix](https://github.com/bambanah/deemix) | [![deemix](https://img.shields.io/github/v/release/unmango/charts?filter=deemix-*&label=deemix)](https://github.com/unmango/charts/releases?q=deemix) | Revived fork |
| [filebrowser](./charts/filebrowser/) | [filebrowser/filebrowser](https://github.com/filebrowser/filebrowser) | [![filebrowser](https://img.shields.io/github/v/release/unmango/charts?filter=filebrowser-*&label=filebrowser)](https://github.com/unmango/charts/releases?q=filebrowser) | Upstream archived |
| [gha-runner-scale-set](./charts/gha-runner-scale-set/) | [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller) | [![gha-runner-scale-set](https://img.shields.io/github/v/release/unmango/charts?filter=gha-runner-scale-set-*&label=gha-runner-scale-set)](https://github.com/unmango/charts/releases?q=gha-runner-scale-set) | Patched fork |
| [hercules-ci-agent](./charts/hercules-ci-agent/) | [hercules-ci/hercules-ci-agent](https://github.com/hercules-ci/hercules-ci-agent) | [![hercules-ci-agent](https://img.shields.io/github/v/release/unmango/charts?filter=hercules-ci-agent-*&label=hercules-ci-agent)](https://github.com/unmango/charts/releases?q=hercules-ci-agent) | Active |
| [mage-server](./charts/mage-server/) | [magefree/mage](https://github.com/magefree/mage) | [![mage-server](https://img.shields.io/github/v/release/unmango/charts?filter=mage-server-*&label=mage-server)](https://github.com/unmango/charts/releases?q=mage-server) | Active |

## Remarks

### actions-runner

Library chart, installs nothing.
Provides pod spec fragments (store volume, mount, `NIX_CONFIG`) for building with Nix.
Templates take the `nix` block as an argument, not `.Values`; see `charts/gha-runner-scale-set/values.yaml` for its shape.

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

### Filebrowser

Upstream is archived (2026-09-01), no further releases or fixes.
The chart still works against the final image.

### Deemix

Upstream (RemixDev) is abandoned.
The chart deploys the maintained fork at [bambanah/deemix](https://github.com/bambanah/deemix).
