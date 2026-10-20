{ pkgs, ... }:
let
  containerdTemplate = ''
  {{ template "base" . }}

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
    runtime_type = "io.containerd.runc.v2"
    privileged_without_host_devices = false
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
    BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime"
  '';

  preStart = pkgs.writeShellScript "k3s-pre-start" ''
  set -eu 
  ${pkgs.coreutils}/bin/mkdir -p /var/lib/rancher/k3s/agent/etc/containerd
  ${pkgs.coreutils}/bin/ln -sfn \
    ${pkgs.writeText "config.toml.tmpl" containerdTemplate} \
    /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl 
  '';
in
{
  environment.systemPackages = [ pkgs.k3s pkgs.kubectl ];

  environment.etc."rancher/k3s/config.yaml".text = ''
  write-kubeconfig-mode: "0644"
  disable:
    - servicelb
  '';

  boot.kernelModules = [ "overlay" "br_netfilter" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
  };

  networking.firewall.trustedInterfaces = [ "cni0" "flannel.1" ];
  networking.firewall.allowedUDPPorts = [ 8472 ];
  networking.firewall.allowedTCPPorts = [ 6443 ];

  systemd.services.k3s = {
    description = "k3s server";
    after = [ "network-online.target" "firewall.service" ];
    wants = [ "network-online.target" "firewall.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "notify";
      KillMode = "process";
      Delegate = "yes";
      Restart = "always";
      RestartSec = "5s";
      LimitNOFILE = 1048576;
      LimitNPROC = "infinity";
      LimitCORE = "infinity";
      TasksMax = "infinity";
      ExecStartPre = preStart;
      ExecStart = "${pkgs.k3s}/bin/k3s server --config /etc/rancher/k3s/config.yaml";
    };
  };
}
