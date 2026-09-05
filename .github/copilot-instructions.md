# Copilot instructions

Full repository conventions live in [AGENTS.md](../AGENTS.md).
Read that file before making changes.

Key points:

- This is a Helm chart repository published to GitHub Pages by `chart-releaser`.
  Charts live under `charts/`: `deemix` and `filebrowser`.
- All tooling (`helm`, `ct`, `cr`, `kind`, `nixfmt`) comes from the Nix devshell in `flake.nix`, loaded by direnv.
  Do not install tools separately.
- Common targets: `make lint`, `make test`, `make check`, `make fmt`, `make package`.
- Bump `version` in a chart's `Chart.yaml` in the same PR as any chart change, otherwise the release workflow never ships it.
  `appVersion` is bumped by Renovate.
- `charts/*/charts/` is gitignored, so run `helm dep update` before linting or templating.
- Adding or renaming anything in a chart's `values.yaml` requires updating that chart's `values.schema.json`.
- Both charts vendor an identical `common.images.image` helper in `templates/_helpers.tpl`; a change to one usually needs mirroring in the other.
