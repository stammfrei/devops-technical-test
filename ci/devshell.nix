{ pkgs, unstable, ... }:

pkgs.mkShell {
  packages = builtins.attrValues {
    inherit (pkgs)
      # --- Linters and formatters
      nixpkgs-fmt
      statix

      # -- Tools
      _1password# Secret management with 1password

      ansible# to get easy access to ansible-doc cli
      ;

    inherit (unstable)
      # project dependencies
      terraform
      packer

      entr# for automatic save > execute feedback loop

      awscli2
      ;
  };

  shellHook = ''
  '';

  TF_LOG = "ERROR";
}
