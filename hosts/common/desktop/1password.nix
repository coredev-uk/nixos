{ meta, ... }:
{
  programs = {
    # CLI
    _1password.enable = true;

    # GUI
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${meta.username}" ];
    };
  };

  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      zen
    '';
    mode = "0755";
  };

}
