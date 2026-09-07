# Changelog

## [0.2.0](https://github.com/unmango/charts/compare/hercules-ci-agent-0.1.0...hercules-ci-agent-0.2.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* StatefulSet.spec.selector is immutable, so an installed release must be deleted with --cascade=orphan before upgrading.

### Features

* use recommended kubernetes labels across all charts ([#79](https://github.com/unmango/charts/issues/79)) ([f20e48a](https://github.com/unmango/charts/commit/f20e48ae3196e5004fbca550a5f5a4b5a7d94256))
