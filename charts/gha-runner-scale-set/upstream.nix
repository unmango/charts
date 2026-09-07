# The upstream chart this one is generated from. Kept as data so the
# derivation and Renovate read the same pin.
#
# The release for a chart version carries no chart tarball, only the
# controller manifest, so the source comes from the repository at the tag
# rather than from a packaged chart.
{
  owner = "actions";
  repo = "actions-runner-controller";
  # renovate: datasource=github-releases depName=actions/actions-runner-controller extractVersion=^gha-runner-scale-set-(?<version>.*)$
  version = "0.14.2";
  hash = "sha256-KAbZWKjJ9vJDeKy1IXU80aZa7+IecVpfo5ZqFGfamgc=";
  # Path to the chart inside the repository.
  chartPath = "charts/gha-runner-scale-set";
}
