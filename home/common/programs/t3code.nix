{ pkgs, ... }:
{
  # T3 Code (github.com/pingdotgg/t3code): the desktop client for the T3 Code environments in the
  # cluster (t3-a.hera.ac, t3-b.hera.ac; home-ops kubernetes/apps/t3). Pair it with a link from
  # `kubectl -n t3 exec deploy/t3-a -- t3 auth pairing create --ttl 1h --base-url
  # https://t3-a.hera.ac`. A client and a server need the same orchestration protocol, not the
  # same release, so nixpkgs' build can trail the cluster's pinned image.
  home.packages = [ pkgs.t3code ];
}
