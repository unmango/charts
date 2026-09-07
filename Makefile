export KUBECONFIG := ${CURDIR}/.kube/config

# lint-% targets are intentionally omitted: .PHONY disables implicit rule
# search, which would stop them matching the lint-% pattern rule below.
.PHONY: lint lint-actions-runner lint-hercules-ci-agent test install changed update check build format fmt kind package push gateway-api chart-gha-runner-scale-set

# charts/gha-runner-scale-set/package.nix uses `|>`, which is still an
# experimental Nix feature. CI enables it through install-nix-action; this is
# what keeps a local `make` working without touching nix.conf.
NIX_FLAGS ?= --extra-experimental-features pipe-operators

# renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
GATEWAY_API_VERSION := 1.6.2

# OCI destination for `make push`. Charts land at $(REGISTRY)/<chart>:<version>.
REGISTRY ?= ghcr.io/unmango/charts

ACTIONS_RUNNER_VERSION := $(shell awk '/^version:/{print $$2}' charts/actions-runner/Chart.yaml)
DEEMIX_VERSION := $(shell awk '/^version:/{print $$2}' charts/deemix/Chart.yaml)
FILEBROWSER_VERSION := $(shell awk '/^version:/{print $$2}' charts/filebrowser/Chart.yaml)
GHA_RUNNER_SCALE_SET_VERSION := $(shell awk '/^version:/{print $$2}' charts/gha-runner-scale-set/Chart.yaml)
HERCULES_CI_AGENT_VERSION := $(shell awk '/^version:/{print $$2}' charts/hercules-ci-agent/Chart.yaml)
MAGE_SERVER_VERSION := $(shell awk '/^version:/{print $$2}' charts/mage-server/Chart.yaml)
REDIS_VERSION := $(shell awk '/^version:/{print $$2}' charts/redis/Chart.yaml)

lint: lint-actions-runner lint-deemix lint-filebrowser lint-gha-runner-scale-set lint-hercules-ci-agent lint-mage-server lint-redis
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml
	helm lint $(dir $<)
	ct lint --config .ct.yaml $(dir $<)

# actions-runner has no dependencies, so no Chart.lock to depend on, and it is a
# library chart, which helm lint accepts but ct install cannot deploy
lint-actions-runner: charts/actions-runner/Chart.yaml .ct.yaml
	helm lint charts/actions-runner
	ct lint --config .ct.yaml charts/actions-runner

# helm lint warns about the missing clusterJoinToken unless it is pointed at the
# ci values, which the lint-% pattern rule has no way to pass
lint-hercules-ci-agent: charts/hercules-ci-agent/Chart.yaml charts/hercules-ci-agent/Chart.lock .ct.yaml
	helm lint charts/hercules-ci-agent --values charts/hercules-ci-agent/ci/default-values.yaml
	ct lint --config .ct.yaml charts/hercules-ci-agent

lint-mage-server: charts/mage-server/Chart.yaml .ct.yaml
	helm lint charts/mage-server
	ct lint --config .ct.yaml charts/mage-server

lint-redis: charts/redis/Chart.yaml .ct.yaml
	helm lint charts/redis
	ct lint --config .ct.yaml charts/redis

test: install

gateway-api: kind
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$(GATEWAY_API_VERSION)/standard-install.yaml
	kubectl wait --for=condition=Established --timeout=60s crd/httproutes.gateway.networking.k8s.io

# hercules-ci-agent can't reach Ready without a real cluster join token,
# gha-runner-scale-set needs the ARC controller and a real GitHub config, and
# actions-runner is a library chart with nothing to deploy
install: .ct.yaml gateway-api
	ct install --config $< --all --excluded-charts actions-runner,gha-runner-scale-set,hercules-ci-agent

# charts/gha-runner-scale-set's templates and values.yaml are generated from the pinned
# upstream chart and the patches beside them. Regenerate after touching either;
# CI fails when the committed tree and a fresh build disagree.
chart-gha-runner-scale-set:
	rm -rf charts/gha-runner-scale-set/templates charts/gha-runner-scale-set/values.yaml
	nix $(NIX_FLAGS) build .#gha-runner-scale-set --out-link .gha-runner-scale-set-result
	cp -rL .gha-runner-scale-set-result/. charts/gha-runner-scale-set/
	chmod -R u+w charts/gha-runner-scale-set/templates charts/gha-runner-scale-set/values.yaml
	rm -f .gha-runner-scale-set-result

changed: .ct.yaml
	ct list-changed --config $<

update:
	nix $(NIX_FLAGS) flake update

check:
	nix $(NIX_FLAGS) flake check

build:
	nix $(NIX_FLAGS) build

format fmt:
	nix $(NIX_FLAGS) fmt

kind: .kube/config

package: .cr-release-packages/actions-runner-$(ACTIONS_RUNNER_VERSION).tgz \
	.cr-release-packages/deemix-$(DEEMIX_VERSION).tgz \
	.cr-release-packages/filebrowser-$(FILEBROWSER_VERSION).tgz \
	.cr-release-packages/gha-runner-scale-set-$(GHA_RUNNER_SCALE_SET_VERSION).tgz \
	.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz \
	.cr-release-packages/mage-server-$(MAGE_SERVER_VERSION).tgz \
	.cr-release-packages/redis-$(REDIS_VERSION).tgz

# Requires a `helm registry login` against the host in $(REGISTRY) first, e.g.
# `helm registry login ghcr.io`. Release pushes happen in
# .github/workflows/release.yml; this is for publishing by hand.
# The loop is one recipe line, so make only sees its last exit status; set -e
# stops it on the first failed push instead of reporting a partial publish.
push: package
	set -e; \
	for pkg in .cr-release-packages/*.tgz; do \
		helm push "$$pkg" "oci://$(REGISTRY)"; \
	done

.kube/config: kind-cluster.yml
	kind create cluster --name chart-testing \
	--kubeconfig $@ \
	--config $<

charts/%/Chart.lock: charts/%/Chart.yaml
	helm dep update $(dir $<)
	@touch $@

index.yaml:
	cr index --config .cr.yaml

# The chart name can't be derived from the package name, since both may contain
# hyphens. Each package names its chart explicitly instead.
.cr-release-packages/actions-runner-$(ACTIONS_RUNNER_VERSION).tgz: CHART := actions-runner
.cr-release-packages/deemix-$(DEEMIX_VERSION).tgz: CHART := deemix
.cr-release-packages/filebrowser-$(FILEBROWSER_VERSION).tgz: CHART := filebrowser
.cr-release-packages/gha-runner-scale-set-$(GHA_RUNNER_SCALE_SET_VERSION).tgz: CHART := gha-runner-scale-set
.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz: CHART := hercules-ci-agent
.cr-release-packages/mage-server-$(MAGE_SERVER_VERSION).tgz: CHART := mage-server
.cr-release-packages/redis-$(REDIS_VERSION).tgz: CHART := redis

.cr-release-packages/%.tgz: .cr.yaml
	cr package charts/$(CHART) --config $<
