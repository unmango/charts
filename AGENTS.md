# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## What this is

A Helm chart repository published to GitHub Pages (`gh-pages` branch, `index.yaml`) by `chart-releaser`.
Six charts live under `charts/`: `actions-runner`, `deemix`, `filebrowser`, `gha-runner-scale-set`, `hercules-ci-agent`, and `mage-server`.

## Tooling

All tools (`helm`, `ct`, `cr`, `kind`, `nixfmt`) come from the Nix devshell in `flake.nix`, loaded automatically by direnv (`.envrc`).
Do not install them separately.

Because of the zsh/Prezto autoload issue, prefix make with `command`:

```sh
command make lint         # helm lint + ct lint, all six charts
command make lint-deemix
command make test         # kind cluster + Gateway API CRDs, then ct install
command make kind         # just create the .kube/config kind cluster
command make gateway-api  # kind cluster + Gateway API standard CRDs
command make changed      # ct list-changed
command make check        # nix flake check
command make fmt          # treefmt (nixfmt, mdformat, actionlint, gofmt)
command make package      # cr package into .cr-release-packages/
```

`test` runs `install`, which depends on `gateway-api` and passes `--excluded-charts actions-runner,gha-runner-scale-set,hercules-ci-agent`, so it is not a plain `ct install --all`.
`ci.yml`'s `test` job excludes the same three.

Every `nix` invocation the Makefile makes goes through its `NIX_FLAGS`, which enables the `pipe-operators` experimental feature that `charts/gha-runner-scale-set/package.nix` needs.
Run those targets through make rather than calling `nix build` directly.
CI does not use the Makefile for this: `ci.yml` runs `nix flake check` on its own and gets `pipe-operators` from the `nix` job's `NIX_CONFIG`, so the feature has to stay enabled in both places.
Nothing installs nix on the `thecluster` runners; their image ships it along with an `/etc/nix/nix.conf` that already sets `experimental-features`, and `NIX_CONFIG` merges on top of that file.
Only `extra-*` settings belong there, since a plain assignment replaces the image's value instead of adding to it.

`KUBECONFIG` is exported by the Makefile to `.kube/config`, so `kubectl`/`helm` in this directory target the local kind cluster.
`kubectl` is not in the devshell; `gateway-api` and `install` need it on `PATH` separately.

Lint or install a single chart directly:

```sh
helm dep update charts/deemix
ct lint --config .ct.yaml --charts charts/deemix
ct install --config .ct.yaml --charts charts/deemix
```

## Release flow

Versions are managed by release-please (`release-please-config.json`, `.release-please-manifest.json`), one `helm` package per chart directory.
On every push to `main` it opens or updates a `chore(main): release` PR that bumps `version` in each affected `Chart.yaml` and writes that chart's `CHANGELOG.md`.
Never hand-edit `version` or `CHANGELOG.md`; the release PR owns them.
A chart is bumped when a `feat` or `fix` commit touches files under its directory, so use Conventional Commits and scope PR titles to the chart.
Both run in `.github/workflows/release.yml` on every push to `main`: `chart-releaser` first publishes any chart whose `version` changed (which happens when the release PR merges), then the `release-please` job runs.
release-please does not create tags or GitHub releases (`skip-github-release`); chart-releaser creates them as `<chart>-<version>`, and release-please reads those tags to find the last release, which is why it runs second.
The `release` job also pushes every package in `.cr-release-packages/` to `oci://ghcr.io/unmango/charts`, which is why it needs `packages: write`.
Each chart becomes the repository `ghcr.io/unmango/charts/<chart>`, tagged with its chart `version`.
chart-releaser packages all six charts on every run, so the push step skips a chart whose `version` tag is already in that repository, mirroring `skip-existing` in `.cr.yaml`.
`make push` does the same by hand against `REGISTRY` (default `ghcr.io/unmango/charts`) after a `helm registry login`, without the skip check.
`appVersion` tracks the upstream image and is bumped by Renovate via the `# renovate: image=...` comments.
Renovate updates under `charts/` commit as `fix(deps): ...` so they trigger a patch release.

## Chart conventions

- `deemix`, `filebrowser`, `hercules-ci-agent` and `mage-server` depend on `common` from `oci://registry-1.docker.io/bitnamicharts` for `common.images.image`, and wrap it in local `image` / `init.image` helpers so templates never call it directly.
  Renovate bumps the pin; a signature change upstream lands in those four wrappers and nowhere else.
  Each also defines its own `labels` and `selectorLabels`, which are still duplicated.
  `actions-runner` takes neither: template names are global to a release, so a library defining unprefixed names would silently override the consumer's own.
  Everything it defines is prefixed `actions-runner.`.
- `gha-runner-scale-set` keeps upstream's `gha-runner-scale-set.labels` rather than this repo's `labels`.
  Upstream already emits the full `app.kubernetes.io/*` set, and its `app.kubernetes.io/name` is the scale set name that the ARC controller keys on.
- `actions-runner` is a library chart, so it renders nothing and cannot be installed; `ct install` excludes it, and its `lint-actions-runner` target is explicit because the `lint-%` pattern rule wants a `Chart.lock`.
  Its templates take the `nix` block as an argument rather than reading `.Values`, since a library's own values land under `.Values.actions-runner` in the consumer.
  `gha-runner-scale-set` depends on it through `file://../actions-runner`, so editing the library means re-running `helm dep update charts/gha-runner-scale-set` before templating, or the stale vendored copy is what renders.
  That dependency is constrained as `>= 0.1.0` rather than pinned, so a release-please bump of the library does not break `gha-runner-scale-set`'s `helm dep update`.
- `gha-runner-scale-set`'s `templates/` and `values.yaml` are generated: `make chart-gha-runner-scale-set` fetches the tag in `charts/gha-runner-scale-set/upstream.nix` and applies `charts/gha-runner-scale-set/patches/*.patch`.
  Edit the patches, never the generated files; CI regenerates and fails on drift.
  `Chart.yaml` is hand-written and deliberately not generated, because release-please rewrites its `version` and a regeneration would revert it.
  To change a patch, unpack the upstream chart, edit, `diff -ruN` against a pristine copy, and rewrite the patch file.
- `deemix` and `filebrowser` declare `oauth2-proxy` as an optional dependency gated on `oauth2-proxy.enabled`.
  Every chart but `actions-runner` has a `Chart.lock`, so the `lint-%` pattern rule covers them all.
  `lint-actions-runner` stays explicit because there is no `Chart.lock` to depend on, and `lint-hercules-ci-agent` because `helm lint` needs `--values charts/hercules-ci-agent/ci/default-values.yaml` to supply the otherwise missing `clusterJoinToken`.
  `charts/*/charts/` is gitignored, so `helm dep update` is required before linting or templating.
- `deemix` and `filebrowser` render an `HTTPRoute`, so the Gateway API CRDs must exist before `ct install`; that is what `make gateway-api` and the equivalent CI step provide.
  Each has a `ci/httproute-values.yaml` alongside `ci/default-values.yaml`, so `ct` installs them twice.
- Every chart but `actions-runner` has a `values.schema.json` that Helm enforces at install time.
  Adding or renaming anything in `values.yaml` requires updating that schema, or installs fail with a validation error.
- `deemix` renders `Deployment` or `StatefulSet` from `.Values.kind`; PVCs only exist in the `StatefulSet` path via `volumeClaimTemplates`.
- `mage-server` speaks raw TCP, so it has no Ingress or HTTPRoute; its `server.*` values become `XMAGE_*` environment variables consumed by the image entrypoint.
- `filebrowser` ships `configmap/*` files (`settings.json`, `setup.sh`) rendered through `tpl` into a ConfigMap, and runs `setup.sh` in an init container to chown volumes and seed the filebrowser DB.
  Edits to `configmap/setup.sh` change runtime behavior, not just packaging.

## Adding a chart

The `lint` and `package` Makefile targets enumerate chart names explicitly; add the new chart to both.
`push` globs `.cr-release-packages/`, so it picks the chart up through `package` with no edit.
Its ghcr package starts private and needs its visibility flipped once after the first release.
A chart that cannot reach Ready in kind also needs adding to `--excluded-charts` in the Makefile's `install` target and in `ci.yml`.
CI (`.github/workflows/ci.yml`) discovers charts automatically through `ct`.

## CI notes

- `ct` validates `Chart.yaml` against `chart_schema.yaml` (yamale) and YAML style against `lintconf.yaml` (yamllint).
- `.ct.yaml` sets `check-version-increment: false` because release-please, not the chart PR, bumps `version`.
- `ct lint` requires full git history to diff against `main`; workflows use `fetch-depth: 0`.
- CI runs on the self-hosted `thecluster` runner, not a GitHub-hosted one.
- The `test` job installs every chart except `actions-runner`, `gha-runner-scale-set` and `hercules-ci-agent`, matching the Makefile's `install` target.
  `filebrowser` provisions a PVC and relies on the kind cluster's default `standard` StorageClass; leaving `persistence.storageClassName` empty omits the field so the cluster default applies.
- `.github/workflows/pr-title.yml` fails a PR whose title is not a Conventional Commit.
  PRs land as squash merges, so the title becomes the subject on `main` and release-please parses it; a title without a type means no chart is bumped.
  Its `types` list mirrors `changelog-sections` in `release-please-config.json`, so adding a type in one place means adding it in the other.
  Renovate's own titles come from `semanticCommits: enabled` in `.github/renovate.json`.
- GitHub Action versions are pinned to commit SHAs and updated by Renovate; keep the `# vN` trailing comments when editing.
