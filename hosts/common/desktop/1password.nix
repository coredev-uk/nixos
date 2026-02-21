{ meta, lib, ... }:
{

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

}
