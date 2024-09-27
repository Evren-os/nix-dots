{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader configuration.
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  networking = {
    hostName = "almajdah";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Asia/Dhaka";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Audio configuration
    hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # Define a user account.
  users.users.evrenos = {
    isNormalUser = true;
    description = "Sayeed Mahmood";
    extraGroups = [ "networkmanager" "wheel" "sudo" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Enable Apps
  programs.firefox.enable = true;
  services.flatpak.enable = true;

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # List packages installed in the system profile.
  environment.systemPackages = with pkgs; [
    # user specific packages
    brave
    fastfetch
    firefox
    flatpak
    git
    gnome.gnome-tweaks
    kitty
    mpv
    neovim
    oh-my-zsh
    qbittorrent
    spotube
    viewnior
    vlc
    vscode
    # System Packages
    curl
    fzf
    gcc
    gnupg
    gnumake
    htop
    ntfs3g
    ripgrep
    tree
    unrar
    unzip
    wget
    zip
    # Fonts
    cantarell-fonts
    # fira-code
    # jetbrains-mono
    # maple-mono
    # maple-mono-NF
    mononoki
    nerdfonts
    noto-fonts
    twitter-color-emoji
  ];


  # System state version.
  system.stateVersion = "24.05";

  # Mount Windows partition.
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/8458B28658B27690"; # UUID of your Windows partition
    fsType = "ntfs-3g";
    options = [
      "rw"
      "auto"
      "user"
      "fmask=0022"
      "dmask=0022"
      "uid=1000"
      "gid=1000"
      "windows_names"
      "locale=en_US.utf8"
      "big_writes"
      "async"
      "noatime"
    ];
  };

  # Create a symbolic link to the Windows user directory.
  systemd.services.create-windows-symlink = {
    description = "Create symlink to Windows user directory";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ln -s /mnt/windows/Users/Evrenos /home/evrenos/windows || true
    '';
  };

  # Enable automatic system upgrades daily
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "daily";
    randomizedDelaySec = "45min";
  };

  # Enable garbage collection every 7 days
  nix = {
    gc = {
      automatic = true;
      dates = "07:00";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
    };
  };

  # Enable SSD TRIM
  services.fstrim.enable = true;

  # Enable zsh
  programs.zsh.enable = true;

  # Enable Bluetooth
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;

  # Security Enhancements
  # security.sudo.enable = true;
  # security.sudo.wheelNeedsPassword = false;

  # Enable AppArmor for enhanced security
  # security.apparmor.enable = true;

  # Enable firewall
  # networking.firewall.allowedTCPPorts = [ 22 ]; # Allow SSH
  # networking.firewall.enable = true;
}
