{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
    loadModels = [ "llama3.2:3b" ];
    environmentVariables = {
      OLLAMA_NUM_PARALLEL = "2";
      OLLAMA_KEEP_ALIVE = "10m";
    };
  };
}
