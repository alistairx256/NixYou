{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.git.enable = true;

  home-manager.sharedModules = [ {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };

    programs.git = {
      enable = true;
      settings.init.defaultBranch = "main";
    };

    home.packages = with pkgs; [
      lazygit
      fzf
      bat
      eza
    ];
  } ];

  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    curl
    wget
    ripgrep
    fd
    jq
    yq-go
    btop
    fastfetch
    pciutils
    usbutils
  ];
}
