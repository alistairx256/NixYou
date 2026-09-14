{ lib, pkgs, ... }:

{
  # VS Code is the only unfree package enabled by this module.
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "vscode";

  # Upstream Node/JDK/Python binaries expect an FHS dynamic loader.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      libffi
      bzip2
      xz
      ncurses
      readline
      sqlite
      libuuid
      libGL
      glib
      fontconfig
      freetype
      alsa-lib
      libx11
      libxext
      libxi
      libxrender
      libxtst
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    (lib.lowPrio gcc)
    gnumake
    just
    cmake
    ninja
    pkg-config

    go
    rustup
    uv
    zig
    llvmPackages.clang
    llvmPackages.clang-tools
    llvmPackages.llvm
    llvmPackages.lld
    llvmPackages.lldb
    vscode
    zed-editor

    # SDKMAN and the Vite+ installer prerequisites.
    bash
    curl
    zip
    unzip
    gnutar
    gzip

    nil
    nixfmt
    (pkgs.writeShellApplication {
      name = "dev-setup";
      runtimeInputs = with pkgs; [ bash curl coreutils gnugrep gnused gawk zip unzip gnutar gzip uv ];
      text = builtins.readFile ../scripts/dev-setup.sh;
    })
  ];

  home-manager.sharedModules = [ ({ config, lib, ... }: {
    home.sessionVariables = {
      VP_HOME = "${config.home.homeDirectory}/.vite-plus";
      SDKMAN_DIR = "${config.home.homeDirectory}/.sdkman";
      UV_PYTHON_PREFERENCE = "only-managed";
    };
    home.sessionPath = [
      "${config.home.homeDirectory}/.vite-plus/bin"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.sdkman/candidates/java/current/bin"
    ];
    programs.zsh.initContent = lib.mkOrder 1500 ''
      if [[ -s "$VP_HOME/env" ]]; then
        source "$VP_HOME/env"
      fi
      # SDKMAN must be initialized last; it manages JAVA_HOME itself.
      if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
      fi
    '';
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  }) ];
}
