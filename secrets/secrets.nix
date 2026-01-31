let
  # Users
  paul = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7";
in
{
  "proton_username.age".publicKeys = [
    paul
  ];
  "proton_password.age".publicKeys = [
    paul
  ];

}
