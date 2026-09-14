{
  description = "Reusable NixOS desktop and development modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    candlelight = {
      url = "github:thep0y/fcitx5-themes-candlelight/60aeaddfb3ecdb6a132e8da7569a6c442e6bb217";
      flake = false;
    };
  };

  outputs = inputs@{ home-manager, ... }:
  let
    homeModules = [
      home-manager.nixosModules.home-manager
      ./modules/home.nix
    ];
    desktopModule = {
      imports = [ ./modules/desktop.nix ];
      _module.args.candlelightSrc = inputs.candlelight;
    };
  in
  {
    nixosModules = {
      base = {
        imports = homeModules ++ [ ./modules/base.nix ];
      };

      home = {
        imports = homeModules;
      };

      desktop = {
        imports = homeModules ++ [ desktopModule ];
      };

      development = {
        imports = homeModules ++ [ ./modules/development.nix ];
      };

      default = {
        imports = homeModules ++ [
          ./modules/base.nix
          desktopModule
          ./modules/development.nix
        ];
      };
    };
  };
}
