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

}
