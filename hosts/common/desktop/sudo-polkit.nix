{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Only needs to be unique on this machine; `local` can't clash with a real domain.
  actionId = "local.sudo";

  # Only the active local session's own user, by their own password, and nothing for SSH or a
  # TTY: those fall through to sudo's usual prompts.
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

  # pam_exec runs this as root inside sudo's authentication, so sudo is its parent and whatever
  # ran sudo (the shell) is the subject polkit asks about, as pkexec does with its own parent.
  # Exit 0 only when the session's agent (the Quickshell dialog) authenticated the user; any
  # other exit falls through to the security key and the password in the terminal.
  sudoPolkit = pkgs.writeShellApplication {
    name = "sudo-polkit";
    runtimeInputs = [
      config.security.polkit.package
      config.systemd.package
      pkgs.coreutils
    ];
    text = ''
      # polkit only takes the question from root (pam_exec's seteuid, below); as anyone else,
      # leave it to the usual prompts.
      [ "$EUID" = 0 ] || exit 1
      sudo_pid=$PPID

      # Not where sudo is told not to ask (-n), reads the password from stdin (-S) or has an
      # askpass helper (-A): scripts rely on those. Options end at the first word that isn't
      # one, skipping the values of options that take one.
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
                # The rest of the word, or else the next one, is this option's value.
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

      # sudo's parent: its pid, start time (against pid reuse) and real uid.
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

      # Only for the user sudo is authenticating, and only with a graphical session to ask in.
      # A process inside a non-graphical session (SSH, a TTY) has no agent to show the dialog;
      # apps in the user manager (the terminal) have no session, and polkit asks in the display one.
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

      # pam_exec's stdout option shows this in the terminal while the dialog is up.
      echo "Authenticate in the dialog, or cancel it to type your password here."
      # Errors go to the journal (journalctl -t sudo-polkit), not the terminal: the password
      # prompt after them says enough there.
      pkcheck --action-id ${actionId} --process "$subject,$started,$uid" \
        --allow-user-interaction --detail command "$command" > /dev/null \
        2> >(systemd-cat --identifier=sudo-polkit --priority=warning)
    '';
  };
in
{
  # sudo asks through the session's polkit agent (the Quickshell dialog,
  # home/common/programs/quickshell/config/modules/PolkitDialog.qml), as macOS's sudo asks for
  # Touch ID. Cancelling it, or no dialog to show (SSH, a TTY, -n/-S/-A), leaves the security key
  # and the password prompt in the terminal as before; sudo's timestamp still spares repeats.
  environment.systemPackages = [ policy ];

  security.pam.services.sudo.rules.auth.polkit = {
    order = config.security.pam.services.sudo.rules.auth.u2f.order - 10;
    control = "sufficient";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    # quiet: a cancelled dialog isn't an error worth printing; stdout: the line above; seteuid:
    # run as root (sudo's effective uid), not as the user (its real one). polkit only lets uid 0
    # pass details (the command in the dialog) or ask about another process.
    args = [
      "quiet"
      "stdout"
      "seteuid"
      (lib.getExe sudoPolkit)
    ];
  };
}
