{ pkgs, unstable, ... }:

pkgs.mkShell {
  packages = builtins.attrValues {
    inherit (pkgs)
      # --- Linters and formatters
      nixpkgs-fmt
      statix

      # -- Tools
      _1password# Secret management with 1password
      ;

    inherit (unstable)
      # project dependencies
      terraform
      packer

      entr# for automatic save > execute feedback loop
      ;
  };

  shellHook = ''
  '';

  TF_LOG = "ERROR";
}
