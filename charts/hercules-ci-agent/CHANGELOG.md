# Changelog

## [0.2.2](https://github.com/unmango/charts/compare/hercules-ci-agent-0.2.1...hercules-ci-agent-0.2.2) (2026-09-12)


### Bug Fixes

* **hercules-ci-agent:** run the standalone image with /nix on the state volume ([#103](https://github.com/unmango/charts/issues/103)) ([6785097](https://github.com/unmango/charts/commit/678509789b743d82cad94690c804a394049f66f8))

## [0.2.1](https://github.com/unmango/charts/compare/hercules-ci-agent-0.2.0...hercules-ci-agent-0.2.1) (2026-09-08)


### Bug Fixes

* **hercules-ci-agent:** auto concurrentTasks ([#96](https://github.com/unmango/charts/issues/96)) ([bd6304d](https://github.com/unmango/charts/commit/bd6304dc25bb997afa0321fa3431544cc1a9be82))


### Code Refactoring

* **charts:** replace local common.images.image with bitnami common library ([bbdc052](https://github.com/unmango/charts/commit/bbdc052df9af6fee74d6e2fe91629aeb0dac473f))
* **charts:** replace vendored `common.images.image` helper with bitnami common dependency ([#88](https://github.com/unmango/charts/issues/88)) ([bbdc052](https://github.com/unmango/charts/commit/bbdc052df9af6fee74d6e2fe91629aeb0dac473f))

## [0.2.0](https://github.com/unmango/charts/compare/hercules-ci-agent-0.1.0...hercules-ci-agent-0.2.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* StatefulSet.spec.selector is immutable, so an installed release must be deleted with --cascade=orphan before upgrading.

### Features

* use recommended kubernetes labels across all charts ([#79](https://github.com/unmango/charts/issues/79)) ([f20e48a](https://github.com/unmango/charts/commit/f20e48ae3196e5004fbca550a5f5a4b5a7d94256))
