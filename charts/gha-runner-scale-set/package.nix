# Generates the parts of this chart that come from upstream: templates/ and
# values.yaml, fetched at a pinned tag and patched.
#
# The patches under patches/ are the source of truth. The generated tree is
# committed anyway so that ct, chart-releaser and `helm template` all work
# against the worktree without a Nix step, and CI fails when the two disagree.
# `make chart-gha-runner-scale-set` is the regeneration entry point.
#
# Chart.yaml is deliberately not generated. release-please rewrites its
# `version`, which a regeneration would revert.
{
  fetchFromGitHub,
  lib,
  runCommand,
}:
let
  upstream = import ./upstream.nix;

  src = fetchFromGitHub {
    inherit (upstream) owner repo hash;
    tag = "gha-runner-scale-set-${upstream.version}";
  };

  patches = lib.filesystem.listFilesRecursive ./patches |> lib.filter (lib.hasSuffix ".patch");
in
runCommand "gha-runner-scale-set-chart-${upstream.version}"
  {
    inherit patches;
    inherit (upstream) chartPath;
    src = "${src}/${upstream.chartPath}";
  }
  ''
    cp -r "$src" chart
    chmod -R u+w chart

    for patch in $patches; do
      echo "applying $(basename "$patch")"
      patch -d chart -p1 --no-backup-if-mismatch < "$patch"
    done

    mkdir -p "$out"
    cp -r chart/templates "$out/templates"
    cp chart/values.yaml "$out/values.yaml"
  ''
