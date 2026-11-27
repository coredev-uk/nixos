# Watchdog from outside the cluster (Gatus, alerting through Pushover): when the cluster, its
# monitoring or Home Assistant is down, nothing inside it can say so.
#
# /var/lib/secrets/gatus.env (root, 0600) is made once from 1Password, never in Git:
#   PUSHOVER_TOKEN     op://kubernetes/alertmanager/ALERTMANAGER_PUSHOVER_TOKEN
#   PUSHOVER_USER_KEY  op://kubernetes/pushover/PUSHOVER_USER_KEY
#   HEARTBEAT_TOKEN    op://kubernetes/alertmanager/HERMES_HEARTBEAT_TOKEN (Alertmanager has it too)
_: {
  services.gatus = {
    enable = true;
    environmentFile = "/var/lib/secrets/gatus.env";
    settings = {
      web.port = 8080;

      alerting.pushover = {
        application-token = "\${PUSHOVER_TOKEN}";
        user-key = "\${PUSHOVER_USER_KEY}";
        title = "hermes";
        priority = 1;
        resolved-priority = 0;
        default-alert = {
          send-on-resolved = true;
          failure-threshold = 3;
          success-threshold = 2;
        };
      };

      endpoints = [
        # Directly on the IoT VLAN, so only Home Assistant itself is tested.
        {
          name = "Home Assistant";
          group = "home";
          url = "http://192.168.130.20:8123/manifest.json";
          interval = "1m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [
            {
              type = "pushover";
              failure-threshold = 5;
              description = "Home Assistant isn't answering on the IoT VLAN";
            }
          ];
        }
        # The way in from the internet: Cloudflare, the tunnel, envoy-external and the cluster's
        # Gatus. Public DNS, because the gateway answers with envoy-external's LAN address, which
        # the IoT VLAN can't reach.
        {
          name = "Status page";
          group = "cluster";
          url = "https://status.hera.ac";
          interval = "2m";
          client.dns-resolver = "tcp://1.1.1.1:53";
          conditions = [ "[STATUS] == 200" ];
          alerts = [
            {
              type = "pushover";
              description = "status.hera.ac isn't reachable from the internet";
            }
          ];
        }
      ];

      # Alertmanager's always-firing Watchdog alert, posted here every 2m30s (home-ops
      # kube-prometheus-stack alertmanagerconfig.yaml). Silence means the cluster, Prometheus or
      # Alertmanager is down. Key: cluster_alertmanager.
      external-endpoints = [
        {
          name = "Alertmanager";
          group = "cluster";
          token = "\${HEARTBEAT_TOKEN}";
          heartbeat.interval = "5m";
          alerts = [
            {
              type = "pushover";
              failure-threshold = 2;
              description = "No Watchdog heartbeat from the cluster's Alertmanager: the cluster or its monitoring is down";
            }
          ];
        }
      ];
    };
  };
}
