{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  users.users.martinsedd.extraGroups = [ "libvirtd" ];

  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
