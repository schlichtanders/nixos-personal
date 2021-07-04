# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, lib, ... }:
{
  # NIX
  # ======================================================================================================

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
      
  # for some reason we need to be explicit about the overlays which we want to use in nixos
  nixpkgs.overlays =
    [
      (import /etc/nixos/overlays/overlay-pdfarranger.nix)
      (import /etc/nixos/overlays/overlay-tiddlydesktop.nix)
      (import /etc/nixos/overlays/overlay-vscode.nix)
      (import /etc/nixos/overlays/overlay-pitch-compensation.nix)
    ];
     
  nix.nixPath =
    # Prepend default nixPath values.
    options.nix.nixPath.default ++ 
    # Append our nixpkgs-overlays.
    [ "nixpkgs-overlays=/etc/nixos/overlays/" ];


  # BOOTING
  # ======================================================================================================

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Enable all sysrq functions (useful to recover from some issues):
  # Documentation: https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
  boot.kernel.sysctl."kernel.sysrq" = 1; # NixOS default: 16 (only the sync command)

  # fixing startup slowdowns due to dhcpcd
  # see https://github.com/NixOS/nixpkgs/issues/60900
  systemd.services.systemd-user-sessions.enable = false;


  # HARDWARE
  # ======================================================================================================

  # Enable CUPS to print documents.
  services.printing.enable = true;
  
  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  # hardware.bluetooth.config.General.Enable = "Source,Sink,Media,Socket";
  hardware.pulseaudio = {
    enable = true;
    # extraModules = [ pkgs.pulseaudio-modules-bt ];
    # package = pkgs.pulseaudioFull;
    # configFile = pkgs.writeText "default.pa" ''
    #   load-module module-bluetooth-policy
    #   load-module module-bluetooth-discover
    #   ## module fails to load with 
    #   ##   module-bluez5-device.c: Failed to get device path from module arguments
    #   ##   module.c: Failed to load module "module-bluez5-device" (argument: ""): initialization failed.
    #   # load-module module-bluez5-device
    #   # load-module module-bluez5-discover
    # '';
    # extraConfig = "
    #   load-module module-switch-on-connect
    # ";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;


  # NETWORKING & SECURITY
  # ======================================================================================================

  # Provide networkmanager for easy wireless configuration.
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false; # Enables wireless support via wpa_supplicant.
  networking.hostName = "gram17"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s20f0u4.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall = {
    allowedTCPPorts = [ /* dropbox */ 17500 ];  
    allowedUDPPorts = [ /* dropbox */ 17500 ];
  };
  

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  security.pam.services.sddm.enableKwallet = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  programs.ssh.startAgent = true;
  programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";
  
  systemd.user.services.ssh-add-my-keys = {
    script = ''
      # adding ssh key using KDE, adapted from https://wiki.archlinux.org/title/KDE_Wallet
      ${pkgs.openssh}/bin/ssh-add -q < /dev/null
    '';
    unitConfig.ConditionUser = "!@system";  # same as ssh-agent
    serviceConfig.Restart = "on-failure";  # in case ssh-agent or kwallet need more time to setup

    wantedBy = [ "default.target" ];
    # assumes that plasma systemd support is activated, see https://blog.davidedmundson.co.uk/blog/plasma-and-the-systemd-startup/
    requires = [ "ssh-agent.service" "app-pam_kwallet_init-autostart.service" ];
    after = [ "ssh-agent.service" "app-pam_kwallet_init-autostart.service" ];
  };

  # fingerprint does not work because there is no driver yet for LG Gram 17
  # services.fprintd.enable = true;
  # security.pam.services.login.fprintAuth = true;
  # security.pam.services.xscreensaver.fprintAuth = true; 


  # ENVIRONMENT AND SHELL
  # ======================================================================================================

  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MEASUREMENT = "en_DE.UTF-8";
    LC_MONETARY = "en_DE.UTF-8";
    LC_COLLATE = "en_DE.UTF-8";
    LC_NUMERIC = "en_DE.UTF-8";
    LC_TIME = "en_DE.UTF-8";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  environment.variables.EDITOR = "kak";
  environment.variables.VISUAL = "code";
  environment.shellAliases = {
    code = "code-insiders";
    jupyter-notebook = "conda-shell -c jupyter-notebook";
    jupyter-lab = "conda-shell -c jupyter-lab";
  };
  environment.shellInit = ''
  '';

  # zsh
  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.histSize = 5000;
  programs.zsh.setOptions = [
    "HIST_IGNORE_DUPS"
    "SHARE_HISTORY"
    "HIST_FCNTL_LOCK"
  ];
  programs.zsh.enableBashCompletion = true;
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.ohMyZsh.enable = true;
  programs.zsh.ohMyZsh.theme ="robbyrussell";
  programs.zsh.ohMyZsh.plugins = [ "git" "sudo" "tmux" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.ssahm = {
    isNormalUser = true;
    description = "Stephan Sahm";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };


  # DESKTOP
  # ======================================================================================================

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.xkbOptions = "caps:escape";

  # Configure keymap in X11
  services.xserver.layout = "de";
  # services.xserver.xkbOptions = "eurosign:e";


  # APPLICATIONS
  # ======================================================================================================

  nixpkgs.config.allowUnfree = true;

  # steam
  programs.steam.enable = true;

  # firefox
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # keepass2
  nixpkgs.config.keepass.plugins = [ pkgs.keepass-keepasshttp ];
  
  # dropbox
  systemd.user.services.dropbox = {
    description = "Dropbox";
    wantedBy = [ "graphical-session.target" ];
    environment = {
      QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
      QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
    };
    serviceConfig = {
      ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
      ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
      KillMode = "control-group"; # upstream recommends process
      Restart = "on-failure";
      PrivateTmp = true;
      ProtectSystem = "full";
      Nice = 10;
    };
  };

  # syncthing
  services.syncthing = {
    enable = true;
    user = "ssahm";
    dataDir = "/home/ssahm/Syncthing";
    configDir = "/home/ssahm/.config/syncthing";
  };

  # search packages by running: `nix search wget`
  environment.systemPackages = 
  with pkgs;
  [
    xsel git wget curl zsh htop tmux vim kakoune unzip xdotool
    expect unixtools.script  # work with terminal color output
    vscode-with-extensions
    ksshaskpass keepass
    libinput-gestures fusuma wmctrl  # touchpad gestures... does not seem to work
    rnix-lsp  # nix language server
    conda  # for global state installation of scientific machine learning, e.g. jupyter-notebook
    julia-stable-bin
    syncthing dropbox-cli
    tdesktop signal-desktop slack
    kate firefox google-chrome plasma-browser-integration
    texlive.combined.scheme-full
    zoom-us teams skype
    gimp
    vlc
    okular pdfarranger pdfsam-basic
    tiddlydesktop
    libreoffice-qt
    obs-studio  # screen recording tool
    ffmpeg-full kdenlive rubberband # video editing tools
  ];

}

