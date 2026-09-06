# UnMango Charts

Random Helm charts you may or may not find useful.

Very much a work in progress, use at your own risk.

## Charts

- [Deemix](https://gitlab.com/Bockiii/deemix-docker) - [Chart](./charts/deemix/)
- [Filebrowser](https://github.com/filebrowser/filebrowser) - [Chart](./charts/filebrowser/)
- [Hercules CI Agent](https://github.com/hercules-ci/hercules-ci-agent) - [Chart](./charts/hercules-ci-agent/)

## Remarks

### Hercules CI Agent

Hercules CI publishes no container image and no Helm chart.
The image this chart deploys comes from [unmango/containers](https://github.com/unmango/containers/tree/main/images/hercules-ci-agent).

Set `clusterJoinToken` to the token from the Hercules CI dashboard, or point `existingSecret` at a Secret holding `cluster-join-token.key`, `binary-caches.json`, and `secrets.json`.
The agent only reads the token at startup.
Changing the chart-managed Secret restarts the pod through a checksum annotation; rotating an `existingSecret` requires restarting the pod by hand.

The image sets `SSL_CERT_FILE` and `NIX_SSL_CERT_FILE` to a store path it does not actually contain, which makes every HTTPS request fail with `unable to get local issuer certificate`.
The chart overrides both to `/etc/ssl/certs/ca-bundle.crt`, which the image does contain.
Once the image is fixed, `caCertFile` can point back at whatever it ships.

There is no `/nix/var/nix` in the image, so Nix chroot stores into `/var/lib/hercules-ci-agent/.local/share/nix/root`.
That makes the agent's state volume the build cache as well, which is why `persistence.size` defaults to `100Gi`.
Losing that volume costs both the warm store and the agent's session key, so the agent registers again as a new one.

The image ships a `/etc/nix/nix.conf` containing the `narinfo-cache-negative-ttl = 0` the agent requires.
Setting `nixConf` or `extraNixConf` replaces that file with a generated one; the required setting is merged in and cannot be overridden.
`extraNixConf: 'trusted-users = root hercules-ci-agent'` silences the agent's trusted-user warning.

Effects run in a nested container and need `effects.enabled: true`, which makes the pod privileged.

The agent only makes outbound connections, so the chart ships no Ingress or HTTPRoute.
The headless Service exists only to satisfy `StatefulSet.spec.serviceName`.
For the same reason the chart is excluded from `ct install`: without a real join token the agent exits on a 401 and can never reach Ready.

### Filebrowser

Filebrowser is looking for maintainers.

<https://github.com/filebrowser/filebrowser#project-status>

### Deemix

Deemix is a little unmaintained at the moment.

<https://gitlab.com/RemixDev/deemix-gui>
<https://gitlab.com/Bockiii/deemix-docker/-/issues/149#note_2637650875>
<https://gitlab.com/deeplydrumming/DeemixFix>
