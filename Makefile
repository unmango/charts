CR   ?= cr
CT   ?= ct
HELM ?= helm
KIND ?= kind

export KUBECONFIG := ${CURDIR}/.kube/config

lint: lint-deemix lint-filebrowser
lint-%: charts/%/Chart.yaml charts/%/Chart.lock .ct.yaml
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

charts/%/Chart.lock: charts/%/Chart.yaml
	$(HELM) dep update $(dir $<)
	@touch $@

index.yaml:
	$(CR) index --config .cr.yaml

.cr-release-packages/%-0.1.0.tgz: charts/%/Chart.yaml .cr.yaml
	$(CR) package charts/$* --config .cr.yaml
