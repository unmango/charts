export KUBECONFIG := ${CURDIR}/.kube/config

# lint-% targets are intentionally omitted: .PHONY disables implicit rule
# search, which would stop them matching the lint-% pattern rule below.
.PHONY: lint test install changed update check build format fmt kind package gateway-api

# renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
GATEWAY_API_VERSION := 1.6.2

lint: lint-deemix lint-filebrowser
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml
	helm lint $(dir $<)
	ct lint --config .ct.yaml $(dir $<)

test: install

gateway-api: kind
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$(GATEWAY_API_VERSION)/standard-install.yaml
	kubectl wait --for=condition=Established --timeout=60s crd/httproutes.gateway.networking.k8s.io

install: .ct.yaml gateway-api
	ct install --config $< --all

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

package: .cr-release-packages/deemix-0.1.0.tgz .cr-release-packages/filebrowser-0.1.0.tgz

.kube/config: kind-cluster.yml
	kind create cluster --name chart-testing \
	--kubeconfig $@ \
	--config $<

charts/%/Chart.lock: charts/%/Chart.yaml
	helm dep update $(dir $<)
	@touch $@

index.yaml:
	cr index --config .cr.yaml

.cr-release-packages/%-0.1.0.tgz: charts/%/Chart.yaml .cr.yaml
	cr package charts/$* --config .cr.yaml
