# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, lib, ... }:
with {
  homedir = "/home/ssahm";
  unstable = import
    <nixos-unstable>
    # reuse the current configuration
    { config = config.nixpkgs.config; };
};
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
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # special samsung driver setup https://github.com/NixOS/nixpkgs/pull/57449
      (<nixpkgs> + /pkgs/misc/cups/drivers/samsung/1.00.36/module.nix)
    ];

  # nixos needs explicit overlays
  nixpkgs.overlays = import ./overlays.nix;

  nix.nixPath =
    # Prepend default nixPath values.
    options.nix.nixPath.default ++
    [
      # use user home for storing and changing nixos configuration
      # (Note that you need to restart the OS for these environment variables to become active)
      "nixos-config=${homedir}/nixos/configuration.nix"
      # Enable our nixpkgs-overlays everywhere
      "nixpkgs-overlays=${homedir}/nixos/overlays.nix"
    ];

  # nix.extraOptions = ''
  #   experimental-features = nix-command
  # '';


  # NIXOS Storage Optimization
  # ======================================================================================================

  # see https://nixos.wiki/wiki/Storage_optimization

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


  # NIXOS COMPATIBILITY FIXES
  # ======================================================================================================

  ##################
  # WARNING IMPURE #
  ##################

  # Fixing binary packages with dynamic linking. E.g. this fixes julia, but may also
  # fix vscode and others. (This assumes that all needed packages are available via
  # parent derivation).
  #
  # For details see https://discourse.nixos.org/t/making-lib64-ld-linux-x86-64-so-2-available/19679/2
  system.activationScripts.ldso = lib.stringAfter [ "usrbinenv" ] ''
    mkdir -m 0755 -p /lib64
    ln -sfn ${pkgs.glibc.out}/lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2.tmp
    mv -f /lib64/ld-linux-x86-64.so.2.tmp /lib64/ld-linux-x86-64.so.2 # atomically replace
  '';

  # BOOTING
  # ======================================================================================================

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
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
  services.samsung-unified-linux-driver_1_00_36.enable = true;
  services.printing.drivers = [ pkgs.epson-201106w ];

  # Enable scanning
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.sane-airscan ]; # driverless scanning

  # Enable OpenGL
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;

  # Enable sound.
  # Using PipeWire https://nixos.wiki/wiki/PipeWire
  # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
  #sound.enable = true;

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;

    config.pipewire = {
      "context.properties" = {
        #"link.max-buffers" = 64;
        "link.max-buffers" = 16; # version < 3 clients can't handle more than this
        "log.level" = 2; # https://docs.pipewire.org/page_daemon.html
        #"default.clock.rate" = 48000;
        #"default.clock.quantum" = 1024;
        #"default.clock.min-quantum" = 32;
        #"default.clock.max-quantum" = 8192;
      };
    };

    # bluetooth
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [{ "device.name" = "~bluez_card.*"; }];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          { "node.name" = "~bluez_input.*"; }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = {
          "node.pause-on-idle" = false;
        };
      }
    ];
  };


  hardware.bluetooth.enable = true;
  # hardware.bluetooth.config.General.Enable = "Source,Sink,Media,Socket";

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  programs.partition-manager.enable = true;


  # FILE SYSTEM
  # ======================================================================================================

  boot.supportedFilesystems = [ "ntfs" "exfat" ];


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

  # Trying to fix DNS problems, hint from https://github.com/NixOS/nixpkgs/issues/63754
  # set to false if you experience "This site can't be reached"
  networking.resolvconf.dnsExtensionMechanism = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall = {
    allowedTCPPorts = [ /* dropbox */ 17500 ];
    allowedUDPPorts = [ /* dropbox */ 17500 /* ausweisapp2 */ 24727 ];
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
    unitConfig.ConditionUser = "!@system"; # same as ssh-agent
    serviceConfig.Restart = "on-failure"; # in case ssh-agent or kwallet need more time to setup

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
    LANGUAGE = "en_US:de_DE";
    # LC_CTYPE = "en_US.UTF-8";  # this is the default Locale
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    # LC_COLLATE = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_MESSAGES = "de_DE.UTF-8";
    # LC_PAPER = "de_DE.UTF-8";
    # LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_ADDRESS = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  environment.variables.EDITOR = "kak";
  environment.variables.VISUAL = "code";
  # environment.shellAliases = { };
  environment.homeBinInPath = true;
  environment.shellInit = ''
    # mapping interrupt away from ctrl-c to ctrl-k
    # (^i won't work, as it interferes with tab completion)
    stty intr ^k

    ##################
    # WARNING IMPURE #
    ##################
    # this fixes python pandas and co
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
    # this fixes python cx_Oracle
    export LD_LIBRARY_PATH="${pkgs.oracle-instantclient.lib}/lib:$LD_LIBRARY_PATH"
    # this adds OpenGL, like documented here https://nixos.wiki/wiki/OpenGL
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
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
  programs.zsh.ohMyZsh.theme = "robbyrussell";
  programs.zsh.ohMyZsh.plugins = [
    "git"
    "sudo"
    "tmux"
  ];
  programs.zsh.ohMyZsh.customPkgs = [
    pkgs.nix-zsh-completions
    pkgs.zsh-nix-shell
  ];

  users.defaultUserShell = pkgs.zsh;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ssahm = {
    isNormalUser = true;
    description = "Stephan Sahm";
    extraGroups = [ "wheel" "networkmanager" "docker" "scanner" "lp" ]; # "scanner" "lp"  are for scanner
  };
  # nixos-rebuild build-vm test user, see https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
  users.users.nixostest = {
    isNormalUser = true;
    initialPassword = "test";
    group = "nixostest";
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

  # Container
  # ======================================================================================================
  virtualisation.docker.enable = true;

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

  # onedrive
  services.onedrive.enable = true;

  # teamviewer
  services.teamviewer.enable = true;

  # Allow Insecure Packages
  nixpkgs.config.permittedInsecurePackages = [
  ];

  # search packages by running: `nix search wget`
  environment.systemPackages = with pkgs; [
    # nix helpers
    nix-index
    bundix
    nodePackages.node2nix
    nix-prefetch-github

    # basics
    rename
    tldr
    xsel
    git
    wget
    curl
    zsh
    htop
    unzip
    zip
    xdotool
    nmap
    inetutils
    killall
    detox # commandline tools
    expect
    unixtools.script # work with terminal color output
    libinput-gestures
    fusuma
    wmctrl # touchpad gestures... does not seem to work
    psensor
    ark # basic ui utils
    rpi-imager
    yelp # gtk help

    # desktop
    libsForQt5.ksystemlog # look into system logs
    libsForQt5.filelight  # inspecting storage usage
    xdg-utils # open links
    krename  # batch file rename

    # security
    keepassxc
    _1password-gui
    openconnect

    # Coding and Editing
    libreoffice-qt
    yakuake
    tmux
    vim
    kakoune # terminal stuff
    unstable.vscode
    kate # graphical editors
    # tiddlydesktop
    unstable.zettlr
    unstable.marktext
    ghostwriter # markdown

    # database
    dbeaver

    # Programming
    docker-compose
    rnix-lsp # nix language server
    conda
    unstable.julia-bin
    nodejs
    clang-tools
    git-clang-format # cpp development
    texlive.combined.scheme-full # LaTeX
    kaggle

    python39
    python39Packages.jupyter-repo2docker
    python39Packages.jupyter-client
    python39Packages.jupyterlab
    python39Packages.notebook # jupyter-notebook
    python39Packages.ipython
    poetry

    # tidyverse palmerpenguins quarto - packages for quarto visual editor
    (rWrapper.override { packages = with rPackages; [ renv tidyverse palmerpenguins quarto ]; })
    (rstudioWrapper.override { packages = with rPackages; [ renv tidyverse palmerpenguins quarto ]; })

    awscli2
    terraform

    jdk8 # e.g. for pyspark and others where it is easiest if java is on the path

    go

    # distributed infrastructure
    kubectl
    minikube
    julia_pod  # defined in overlay

    # foldersync
    syncthing
    dropbox-cli

    # messenger
    konversation # irc
    tdesktop
    signal-desktop
    slack
    element-desktop
    zoom-us
    teams
    skypeforlinux
    discord

    # browser
    brave
    firefox
    tor-browser-bundle-bin
    plasma-browser-integration # firefox extension
    chromium
    google-chrome # legacy

    # mail
    # libsForQt5.kontact libsForQt5.kmail libsForQt5.kmbox libsForQt5.kmail-account-wizard libsForQt5.korganizer libsForQt5.knotes libsForQt5.akregator libsForQt5.kaddressbook libsForQt5.akonadi  # kde kontact suite
    thunderbird

    # images
    digikam
    gwenview # view
    gimp
    inkscape
    scribus # editing
    graphviz
    imagemagick
    libwebp # terminal tools
    drawio

    # pdf
    # gui pdf tools
    okular
    evince
    calibre
    masterpdfeditor # ui pdf reader, adobe-reader is insecure
    pdfarranger # ui pdf merger
    # terminal pdf tools
    pdfsam-basic
    pdf2svg
    pandoc
    poppler_utils # e.g. pdfinfo
    ocamlPackages.cpdf

    # audio
    pavucontrol
    easyeffects
    audacity
    ardour
    qtractor

    # video
    vlc
    guvcview
    v4l-utils # webcam control, qv4l2 is part of v4l-utils
    obs-studio # screen recording tool
    kdenlive
    ffmpeg-full
    rubberband # video editing tools

    # musicsheets
    musescore

    # anderes
    AusweisApp2
    libsForQt5.kruler
  ];
}

