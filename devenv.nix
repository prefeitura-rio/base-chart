{ pkgs, ... }:

{
  packages = with pkgs; [ kubernetes-helm ];

  tasks = {
    "helm:lint" = {
      description = "Validate chart structure and best practices";
      exec = "helm lint chart/";
    };

    "helm:test" = {
      description = "Run all chart unit tests";
      after = [ "helm:lint" ];
      exec = "${pkgs.kubernetes-helmPlugins.helm-unittest}/helm-unittest/untt chart/";
    };

    "helm:debug" = {
      description = "Generate all rendered templates to the debug/ directory";
      exec = ''
        mkdir -p debug
        helm template debug-release chart/ --output-dir debug/
      '';
    };

    "helm:show" = {
      description = "Display all rendered resources to stdout";
      exec = "helm template show-release chart/ --set image.repository=nginx --set image.tag=alpine";
    };

    "helm:clean" = {
      description = "Remove debug/ directory and other build artifacts";
      exec = "rm -rf debug/";
    };

    "helm:info" = {
      description = "Show chart metadata and default values";
      exec = ''
        helm show chart chart/
        echo ""
        helm show values chart/
      '';
    };

    "helm:package" = {
      description = "Create a .tgz package of the chart";
      exec = "helm package chart/";
    };
  };
}
