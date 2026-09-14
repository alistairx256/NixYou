{ config, candlelightSrc, pkgs, ... }:

let
  # false: Fcitx Pinyin + Moegirl; true: Rime + Rime Ice.
  useRime = true;
  candlelight = pkgs.stdenvNoCC.mkDerivation {
    pname = "fcitx5-themes-candlelight";
    version = "unstable-60aeadd";
    src = candlelightSrc;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/fcitx5/themes"
      for theme in */theme.conf; do
        cp -r "$(dirname "$theme")" "$out/share/fcitx5/themes/"
      done
      test -f "$out/share/fcitx5/themes/macOS-dark/theme.conf"
      runHook postInstall
    '';
  };
in
{
  programs.niri.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.dms-shell = {
    enable = true;
    systemd.enable = true;
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session"
      + " --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
      + " --cmd ${config.programs.niri.package}/bin/niri-session";
  };

  security.polkit.enable = true;
  services.dbus.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    # Each compositor module supplies its own screencast portal.
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      candlelight
    ] ++ (if useRime then [
      (fcitx5-rime.override { rimeDataPkgs = [ rime-ice ]; })
    ] else [
      fcitx5-chinese-addons
      fcitx5-pinyin-moegirl
    ]);
    fcitx5.settings = {
      inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = if useRime then "rime" else "pinyin";
        };
        "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
        "Groups/0/Items/1" = {
          Name = if useRime then "rime" else "pinyin";
          Layout = "";
        };
        GroupOrder."0" = "Default";
      };
      addons.classicui.globalSection = {
        Theme = "macOS-dark";
        DarkTheme = "macOS-dark";
        Font = "Noto Sans CJK SC 12";
      };
    };
  };

  environment.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULES = "wayland;fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
    NIXOS_OZONE_WL = "1";
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    serif = [ "Noto Serif" "Noto Serif CJK SC" ];
    monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC" ];
    emoji = [ "Noto Color Emoji" ];
  };

  home-manager.sharedModules = [ ({ lib, ... }: {
    programs.kitty = {
      enable = true;
      extraConfig = builtins.readFile ../config/kitty/kitty.conf;
    };
    programs.ghostty.enable = true;
    xdg.configFile."ghostty/config".source = ../config/ghostty/config;

    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-im-module = "fcitx";
      gtk4.extraConfig.gtk-im-module = "fcitx";
    };
    xdg.configFile."niri/config.kdl".source = ../config/niri/config.kdl;
    xdg.configFile."hypr/hyprland.lua".source = ../config/hypr/hyprland.lua;
    xdg.dataFile."fcitx5/rime/default.custom.yaml" = lib.mkIf useRime {
      text = ''
        patch:
          __include: rime_ice_suggestion:/
          schema_list:
            - schema: rime_ice
      '';
    };
    # One instance per graphical session, stopped on logout.
    systemd.user.services.fcitx5 = {
      Unit = {
        Description = "Fcitx5 input method";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    # The session service above owns startup instead of XDG autostart.
    xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Fcitx 5
      Hidden=true
    '';
  }) ];

  environment.systemPackages = with pkgs; [
    kitty
    ghostty
    firefox
    nautilus
    xwayland-satellite
    wl-clipboard
    grim
    slurp
    playerctl
    brightnessctl
    pavucontrol
  ];
}
