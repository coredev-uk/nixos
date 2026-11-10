{ meta, lib, ... }:
{
  # Only for meta.passwordManager = "1password" (flake.nix). Proton Pass needs nothing at system
  # level: its app, CLI and SSH agent are Home Manager's (home/common/desktop, home/common/shell).
  config = lib.mkIf (meta.passwordManager == "1password") {
    programs = {
      # CLI
      _1password.enable = true;

      # GUI
      _1password-gui = {
        enable = true;
      }
      // lib.optionalAttrs meta.isDesktop {
        polkitPolicyOwners = [ meta.username ];
      };
    };

    environment.etc."1password/custom_allowed_browsers" = lib.mkIf meta.isDesktop {
      text = ''
        zen
      '';
      mode = "0755";
    };
  };
}
