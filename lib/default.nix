{
  self,
  inputs,
  outputs,
  username,
  ...
}:
let
  helpers = import ./helpers.nix {
    inherit
      self
      inputs
      outputs
      username
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
