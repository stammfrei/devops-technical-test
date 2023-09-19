{ pkgs, lib ? pkgs.lib }:

pkgs.dockerTools.buildImage {
  name = "base";
  tag = "latest";

  copyToRoot = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    fakeNss
  ];
}
