_ != mkdir -p bin

GOARCH != go env GOARCH
GOOS   != go env GOOS

CR   ?= go tool cr
CT   ?= go tool ct
HELM ?= bin/helm
KIND ?= go tool kind

export KUBECONFIG := ${CURDIR}/.kube/config

# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION := 3.19.0

lint: lint-deemix lint-filebrowser
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml | $(HELM)
	$(HELM) lint $(dir $<)
	$(CT) lint --config .ct.yaml $(dir $<)

test: kind install

install: .ct.yaml
	$(CT) install --config $< --all

changed: .ct.yaml
	$(CT) list-changed --config $<

kind: .kube/config

package: .cr-release-packages/deemix-0.1.0.tgz .cr-release-packages/filebrowser-0.1.0.tgz

.kube/config: kind-cluster.yml
	$(KIND) create cluster --name chart-testing \
	--kubeconfig $@ \
	--config $<

charts/%/Chart.yaml:
	$(HELM) create charts/$*

charts/%/Chart.lock: charts/%/Chart.yaml | $(HELM)
	$(HELM) dep update $(dir $<)
	@touch $@

index.yaml:
	$(CR) index --config .cr.yaml

.cr-release-packages/%-0.1.0.tgz: charts/%/Chart.yaml .cr.yaml
	$(CR) package charts/$* --config .cr.yaml

bin/cr:
	curl -L https://github.com/helm/chart-releaser/releases/download/v${CHART_RELEASER_VERSION}/chart-releaser_${CHART_RELEASER_VERSION}_${GOOS}_${GOARCH}.tar.gz \
	| tar -zxvO cr > $@ && chmod +x $@

bin/ct:
	curl -L https://github.com/helm/chart-testing/releases/download/v${CHART_TESTING_VERSION}/chart-testing_${CHART_TESTING_VERSION}_${GOOS}_${GOARCH}.tar.gz \
	| tar -zxvO ct > $@ && chmod +x $@

bin/helm:
	curl -L https://get.helm.sh/helm-v${HELM_VERSION}-${GOOS}-${GOARCH}.tar.gz \
	| tar -zxvO ${GOOS}-${GOARCH}/helm > $@ && chmod +x $@
