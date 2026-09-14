{ lib, ... }:

{
  # Users are registered by the consuming NixOS configuration.
  # Home Manager derives each user's name and home directory from users.users.
  home-manager = {
    useGlobalPkgs = lib.mkDefault true;
    useUserPackages = lib.mkDefault true;
  };
}
