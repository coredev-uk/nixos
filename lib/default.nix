{
  self,
  inputs,
  outputs,
  username,
  passwordManager,
  ...
}:
let
  helpers = import ./helpers.nix {
    inherit
      self
      inputs
      outputs
      username
      passwordManager
      ;
  };
in
{
  inherit (helpers)
    mkHome
    mkHost
    mkDarwin
    forAllSystems
    ;
}
