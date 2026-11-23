{ pkgs, ... }:
{
  # Desktop client for the cluster's T3 environments (t3-a/t3-b.hera.ac; home-ops kubernetes/apps/t3).
  # Pair: `kubectl -n t3 exec deploy/t3-a -- t3 auth pairing create --ttl 1h --base-url https://t3-a.hera.ac`.
  # Only the orchestration protocol must match, so nixpkgs' build may trail the cluster.
  home.packages = [ pkgs.t3code ];
}
