export KUBECONFIG := ${CURDIR}/.kube/config

# lint-% targets are intentionally omitted: .PHONY disables implicit rule
# search, which would stop them matching the lint-% pattern rule below.
.PHONY: lint lint-actions-runner lint-hercules-ci-agent lint-mage-server test install changed update check build format fmt kind package gateway-api chart-gharc

# renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
GATEWAY_API_VERSION := 1.6.2

ACTIONS_RUNNER_VERSION := $(shell awk '/^version:/{print $$2}' charts/actions-runner/Chart.yaml)
DEEMIX_VERSION := $(shell awk '/^version:/{print $$2}' charts/deemix/Chart.yaml)
FILEBROWSER_VERSION := $(shell awk '/^version:/{print $$2}' charts/filebrowser/Chart.yaml)
GHARC_VERSION := $(shell awk '/^version:/{print $$2}' charts/gharc/Chart.yaml)
HERCULES_CI_AGENT_VERSION := $(shell awk '/^version:/{print $$2}' charts/hercules-ci-agent/Chart.yaml)
MAGE_SERVER_VERSION := $(shell awk '/^version:/{print $$2}' charts/mage-server/Chart.yaml)

lint: lint-actions-runner lint-deemix lint-filebrowser lint-gharc lint-hercules-ci-agent lint-mage-server
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml
	helm lint $(dir $<)
	ct lint --config .ct.yaml $(dir $<)

# actions-runner, hercules-ci-agent and mage-server have no dependencies, so no Chart.lock to depend on
# actions-runner is a library chart, which helm lint accepts but ct install cannot deploy
lint-actions-runner: charts/actions-runner/Chart.yaml .ct.yaml
	helm lint charts/actions-runner
	ct lint --config .ct.yaml charts/actions-runner

# hercules-ci-agent and mage-server have no dependencies, so no Chart.lock to depend on
lint-hercules-ci-agent: charts/hercules-ci-agent/Chart.yaml .ct.yaml
	helm lint charts/hercules-ci-agent --values charts/hercules-ci-agent/ci/default-values.yaml
	ct lint --config .ct.yaml charts/hercules-ci-agent

lint-mage-server: charts/mage-server/Chart.yaml .ct.yaml
	helm lint charts/mage-server
	ct lint --config .ct.yaml charts/mage-server

test: install

gateway-api: kind
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$(GATEWAY_API_VERSION)/standard-install.yaml
	kubectl wait --for=condition=Established --timeout=60s crd/httproutes.gateway.networking.k8s.io

# hercules-ci-agent can't reach Ready without a real cluster join token, gharc
# needs the ARC controller and a real GitHub config, and actions-runner is a
# library chart with nothing to deploy
install: .ct.yaml gateway-api
	ct install --config $< --all --excluded-charts actions-runner,gharc,hercules-ci-agent

# charts/gharc's templates and values.yaml are generated from the pinned
# upstream chart and the patches beside them. Regenerate after touching either;
# CI fails when the committed tree and a fresh build disagree.
chart-gharc:
	rm -rf charts/gharc/templates charts/gharc/values.yaml
	nix build .#gharc --out-link .gharc-result
	cp -rL .gharc-result/. charts/gharc/
	chmod -R u+w charts/gharc/templates charts/gharc/values.yaml
	rm -f .gharc-result

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

package: .cr-release-packages/actions-runner-$(ACTIONS_RUNNER_VERSION).tgz \
	.cr-release-packages/deemix-$(DEEMIX_VERSION).tgz \
	.cr-release-packages/filebrowser-$(FILEBROWSER_VERSION).tgz \
	.cr-release-packages/gharc-$(GHARC_VERSION).tgz \
	.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz \
	.cr-release-packages/mage-server-$(MAGE_SERVER_VERSION).tgz

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
.cr-release-packages/gharc-$(GHARC_VERSION).tgz: CHART := gharc
.cr-release-packages/hercules-ci-agent-$(HERCULES_CI_AGENT_VERSION).tgz: CHART := hercules-ci-agent
.cr-release-packages/mage-server-$(MAGE_SERVER_VERSION).tgz: CHART := mage-server

.cr-release-packages/%.tgz: .cr.yaml
	cr package charts/$(CHART) --config $<
