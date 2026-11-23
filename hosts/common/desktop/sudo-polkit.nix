{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Unique on this machine only.
  actionId = "local.sudo";

  # Active local session's own user, own password; SSH/TTY fall through to sudo's prompts.
  policy = pkgs.writeTextDir "share/polkit-1/actions/${actionId}.policy" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <action id="${actionId}">
        <description>Run a command with sudo</description>
        <message>Authentication is needed to run “$(command)”</message>
        <defaults>
          <allow_any>no</allow_any>
          <allow_inactive>no</allow_inactive>
          <allow_active>auth_self</allow_active>
        </defaults>
      </action>
    </policyconfig>
  '';

  # pam_exec runs this as root inside sudo's auth, so sudo is the parent and its caller (the shell)
  # is polkit's subject, as with pkexec. Exit 0 only if the session agent authenticated the user;
  # any other exit falls through to the key and password.
  sudoPolkit = pkgs.writeShellApplication {
    name = "sudo-polkit";
    runtimeInputs = [
      config.security.polkit.package
      config.systemd.package
      pkgs.coreutils
    ];
    text = ''
      # polkit only takes the question from root (pam_exec's seteuid); else use the usual prompts.
      [ "$EUID" = 0 ] || exit 1
      sudo_pid=$PPID

      # No dialog where sudo must not ask (-n), reads stdin (-S) or has askpass (-A): scripts use
      # those. Options end at the first non-option word, skipping values of options that take one.
      mapfile -d "" argv < "/proc/$sudo_pid/cmdline"
      skip=0
      for arg in "''${argv[@]:1}"; do
        if [ "$skip" = 1 ]; then
          skip=0
          continue
        fi
        case "$arg" in
          --) break ;;
          --non-interactive | --stdin | --askpass) exit 1 ;;
          --close-from | --chdir | --group | --host | --prompt | --chroot | --role | --type | \
            --command-timeout | --other-user | --user) skip=1 ;;
          --*) ;;
          -?*)
            flags=''${arg#-}
            while [ -n "$flags" ]; do
              flag=''${flags:0:1}
              flags=''${flags:1}
              case "$flag" in
                n | S | A) exit 1 ;;
                # Value is the rest of the word, else the next one.
                C | D | g | p | R | r | t | T | U | u)
                  [ -z "$flags" ] && skip=1
                  break
                  ;;
              esac
            done
            ;;
          *) break ;;
        esac
      done

      # sudo's parent: pid, start time (pid reuse) and real uid.
      stat=$(< "/proc/$sudo_pid/stat")
      read -r -a fields <<< "''${stat##*) }"
      subject=''${fields[1]}
      stat=$(< "/proc/$subject/stat")
      read -r -a fields <<< "''${stat##*) }"
      started=''${fields[19]}
      uid=
      while read -r key real _; do
        [ "$key" = "Uid:" ] && uid=$real
      done < "/proc/$subject/status"

      # Only for the authenticating user, and only with a graphical session to ask in: SSH/TTY
      # sessions have no agent; user-manager apps (terminal) have no session, polkit asks the display one.
      [ -n "$uid" ] && [ "$uid" != 0 ] && [ "$uid" = "$(id -u "$PAM_USER")" ] || exit 1
      [ -n "$(loginctl show-user "$uid" --property Display --value 2>/dev/null)" ] || exit 1
      if [[ "$(< "/proc/$subject/cgroup")" =~ /session-([^./]+)\.scope ]]; then
        case "$(loginctl show-session "''${BASH_REMATCH[1]}" --property Type --value)" in
          wayland | x11) ;;
          *) exit 1 ;;
        esac
      fi

      command="''${argv[*]}"
      if [ "''${#command}" -gt 200 ]; then
        command="''${command:0:199}…"
      fi

      # Shown in the terminal while the dialog is up (pam_exec stdout).
      echo "Authenticate in the dialog, or cancel it to type your password here."
      # Errors go to the journal (`journalctl -t sudo-polkit`), not the terminal.
      pkcheck --action-id ${actionId} --process "$subject,$started,$uid" \
        --allow-user-interaction --detail command "$command" > /dev/null \
        2> >(systemd-cat --identifier=sudo-polkit --priority=warning)
    '';
  };
in
{
  # sudo asks through the session's polkit agent (Quickshell PolkitDialog.qml), like macOS Touch ID.
  # Cancelled or unavailable (SSH, TTY, -n/-S/-A): the security key and password prompt as before.
  environment.systemPackages = [ policy ];

  security.pam.services.sudo.rules.auth.polkit = {
    order = config.security.pam.services.sudo.rules.auth.u2f.order - 10;
    control = "sufficient";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    # quiet: no noise on a cancelled dialog; stdout: the line above; seteuid: run as root (sudo's
    # euid), since polkit only takes details (the command shown) or other processes' questions from uid 0.
    args = [
      "quiet"
      "stdout"
      "seteuid"
      (lib.getExe sudoPolkit)
    ];
  };
}
