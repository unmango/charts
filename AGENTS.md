# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## What this is

A Helm chart repository published to GitHub Pages (`gh-pages` branch, `index.yaml`) by `chart-releaser`.
Four charts live under `charts/`: `deemix`, `filebrowser`, `hercules-ci-agent`, and `mage-server`.

## Tooling

All tools (`helm`, `ct`, `cr`, `kind`, `nixfmt`) come from the Nix devshell in `flake.nix`, loaded automatically by direnv (`.envrc`).
Do not install them separately.

Because of the zsh/Prezto autoload issue, prefix make with `command`:

```sh
command make lint      # helm lint + ct lint, both charts
command make lint-deemix
command make test      # creates a kind cluster, then ct install --all
command make kind      # just create the .kube/config kind cluster
command make check     # nix flake check
command make fmt       # treefmt (nixfmt, mdformat, actionlint, gofmt)
command make package   # cr package into .cr-release-packages/
```

`KUBECONFIG` is exported by the Makefile to `.kube/config`, so `kubectl`/`helm` in this directory target the local kind cluster.

Lint or install a single chart directly:

```sh
helm dep update charts/deemix
ct lint --config .ct.yaml --charts charts/deemix
ct install --config .ct.yaml --charts charts/deemix
```

## Release flow

`chart-releaser` (`.github/workflows/release.yml`) runs on every push to `main` and cuts a release for any chart whose `version` in `Chart.yaml` changed.
Bump `version` in `Chart.yaml` by hand in the same PR as any chart change, otherwise the change never ships.
`appVersion` tracks the upstream image and is bumped by Renovate via the `# renovate: image=...` comments.

## Chart conventions

- Every chart vendors an identical `common.images.image` helper in `templates/_helpers.tpl`, copied from bitnami/common.
  Templates call the local `image` / `init.image` wrappers rather than the bitnami one directly.
  A change to one chart's helper usually needs mirroring in the others.
- `deemix` and `filebrowser` declare `oauth2-proxy` as an optional dependency gated on `oauth2-proxy.enabled`.
  `hercules-ci-agent` and `mage-server` have no dependencies and no `Chart.lock`.
  `charts/*/charts/` is gitignored, so `helm dep update` is required before linting or templating.
- Each chart has a `values.schema.json` that Helm enforces at install time.
  Adding or renaming anything in `values.yaml` requires updating that schema, or installs fail with a validation error.
- `deemix` renders `Deployment` or `StatefulSet` from `.Values.kind`; PVCs only exist in the `StatefulSet` path via `volumeClaimTemplates`.
- `mage-server` speaks raw TCP, so it has no Ingress or HTTPRoute; its `server.*` values become `XMAGE_*` environment variables consumed by the image entrypoint.
- `filebrowser` ships `configmap/*` files (`settings.json`, `setup.sh`) rendered through `tpl` into a ConfigMap, and runs `setup.sh` in an init container to chown volumes and seed the filebrowser DB.
  Edits to `configmap/setup.sh` change runtime behavior, not just packaging.

## Adding a chart

The `lint` and `package` Makefile targets enumerate chart names explicitly; add the new chart to both.
CI (`.github/workflows/ci.yml`) discovers charts automatically through `ct`.

## CI notes

- `ct` validates `Chart.yaml` against `chart_schema.yaml` (yamale) and YAML style against `lintconf.yaml` (yamllint).
- `ct lint` requires full git history to diff against `main`; workflows use `fetch-depth: 0`.
- The `test` job installs every chart.
  `filebrowser` provisions a PVC and relies on the kind cluster's default `standard` StorageClass; leaving `persistence.storageClassName` empty omits the field so the cluster default applies.
- GitHub Action versions are pinned to commit SHAs and updated by Renovate; keep the `# vN` trailing comments when editing.
