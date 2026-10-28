# Changelog

## [0.4.2](https://github.com/unmango/charts/compare/deemix-0.4.1...deemix-0.4.2) (2026-10-28)


### Bug Fixes

* **deps:** update ghcr.io/bambanah/deemix docker tag to v4.8.0 ([#128](https://github.com/unmango/charts/issues/128)) ([a51ea58](https://github.com/unmango/charts/commit/a51ea5826e7491f439460f4955ab3518f4ab2cf0))
* **deps:** update helm release oauth2-proxy to v10.7.1 ([#125](https://github.com/unmango/charts/issues/125)) ([f7b62cf](https://github.com/unmango/charts/commit/f7b62cf56fd40b225da4a1d74eca4f041deccac0))

## [0.4.1](https://github.com/unmango/charts/compare/deemix-0.4.0...deemix-0.4.1) (2026-09-08)


### Code Refactoring

* **charts:** replace local common.images.image with bitnami common library ([bbdc052](https://github.com/unmango/charts/commit/bbdc052df9af6fee74d6e2fe91629aeb0dac473f))
* **charts:** replace vendored `common.images.image` helper with bitnami common dependency ([#88](https://github.com/unmango/charts/issues/88)) ([bbdc052](https://github.com/unmango/charts/commit/bbdc052df9af6fee74d6e2fe91629aeb0dac473f))

## [0.4.0](https://github.com/unmango/charts/compare/deemix-0.3.0...deemix-0.4.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* StatefulSet.spec.selector is immutable, so an installed release must be deleted with --cascade=orphan before upgrading.

### Features

* use recommended kubernetes labels across all charts ([#79](https://github.com/unmango/charts/issues/79)) ([f20e48a](https://github.com/unmango/charts/commit/f20e48ae3196e5004fbca550a5f5a4b5a7d94256))
