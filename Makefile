_ != mkdir -p bin

GOARCH != go env GOARCH
GOOS   != go env GOOS

CR   ?= bin/cr
HELM ?= bin/helm

# renovate: datasource=github-releases depName=helm/chart-releaser
CHART_RELEASER_VERSION := 1.8.1

# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION := 3.19.0

lint: lint-deemix lint-filebrowser
lint-%: charts/%/Chart.yaml | $(HELM)
	$(HELM) lint $(dir $<)

index.yaml: | $(CR)
	$(CR) index --config .cr.yaml

.cr-release-packages/%-0.1.0.tgz: charts/%/Chart.yaml
	$(CR) package charts/$* --config .cr.yaml

bin/cr:
	curl -L https://github.com/helm/chart-releaser/releases/download/v${CHART_RELEASER_VERSION}/chart-releaser_${CHART_RELEASER_VERSION}_${GOOS}_${GOARCH}.tar.gz \
	| tar -zxvO cr > $@ && chmod +x $@

bin/helm:
	curl -L https://get.helm.sh/helm-v${HELM_VERSION}-${GOOS}-${GOARCH}.tar.gz \
	| tar -zxvO ${GOOS}-${GOARCH}/helm > $@ && chmod +x $@
