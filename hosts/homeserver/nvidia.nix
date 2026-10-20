{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    nvidiaPersistenced = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  boot.kernelModules = [ "nvidia_uvm" ];
}
