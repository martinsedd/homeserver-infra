{ ... }:
{
  imports = [
    ./hardware.nix
    ./base.nix
    ./nvidia.nix
    ./k3s.nix
    ./backup.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homeserver";
  networking.useDHCP = true;

  users.users.martinsedd = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHo8rCw1qpHrTsBupOSiVf0Fq3Xe0o7vqnJsQ9CqXMih rec.eddie@gmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
