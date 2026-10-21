{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./base.nix
    ./nvidia.nix
    ./k3s.nix
    ./backup.nix
    ./ollama.nix
    ./vm.nix
  ];

  nixpkgs.config.allowUnfree = true;

  sops = {
    defaultSopsFile = ../../secrets/homeserver.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.restic-password = {
      owner = "root";
      mode = "0400";
    };
  };

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
