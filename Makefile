export KUBECONFIG := ${CURDIR}/.kube/config

# lint-% targets are intentionally omitted: .PHONY disables implicit rule
# search, which would stop them matching the lint-% pattern rule below.
.PHONY: lint lint-hercules-ci-agent test install changed update check build format fmt kind package gateway-api

# renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
GATEWAY_API_VERSION := 1.6.2

DEEMIX_VERSION := $(shell awk '/^version:/{print $$2}' charts/deemix/Chart.yaml)
FILEBROWSER_VERSION := $(shell awk '/^version:/{print $$2}' charts/filebrowser/Chart.yaml)
HERCULES_CI_AGENT_VERSION := $(shell awk '/^version:/{print $$2}' charts/hercules-ci-agent/Chart.yaml)

lint: lint-deemix lint-filebrowser lint-hercules-ci-agent
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml
	helm lint $(dir $<)
	ct lint --config .ct.yaml $(dir $<)

# hercules-ci-agent has no dependencies, so no Chart.lock to depend on
lint-hercules-ci-agent: charts/hercules-ci-agent/Chart.yaml .ct.yaml
	helm lint charts/hercules-ci-agent
	ct lint --config .ct.yaml charts/hercules-ci-agent

test: install

gateway-api: kind
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$(GATEWAY_API_VERSION)/standard-install.yaml
	kubectl wait --for=condition=Established --timeout=60s crd/httproutes.gateway.networking.k8s.io

# hercules-ci-agent can't reach Ready without a real cluster join token
install: .ct.yaml gateway-api
	ct install --config $< --all --excluded-charts hercules-ci-agent

changed: .ct.yaml
	ct list-changed --config $<

update:
	nix flake update

check:
	nix flake check

build:
	nix build

format fmt:
	nix fmt

kind: .kube/config

package: .cr-release-packages/deemix-$(DEEMIX_VERSION).tgz \
	.cr-release-packages/filebrowser-$(FILEBROWSER_VERSION).tgz \
	.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz

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
.cr-release-packages/deemix-$(DEEMIX_VERSION).tgz: CHART := deemix
.cr-release-packages/filebrowser-$(FILEBROWSER_VERSION).tgz: CHART := filebrowser
.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz: CHART := hercules-ci-agent

.cr-release-packages/%.tgz: .cr.yaml
	cr package charts/$(CHART) --config $<
