{ pkgs, unstable, ... }:

pkgs.mkShell {
  packages = builtins.attrValues {
    inherit (pkgs)
      # --- Linters and formatters
      nixpkgs-fmt
      statix

      ncurses# for tput

      # -- Tools
      ansible# to get easy access to ansible-doc cli
      coreutils
      docker
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
