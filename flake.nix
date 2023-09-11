{
  description = "Technical test repo";

  inputs = {
    # I fetch stable and unstable
    # The unstable repo allow me to get more up-to-date tools
    nixpkgs = { url = "github:NixOS/nixpkgs/release-22.05"; };
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    # Generate vms|iso|more from nixos confs
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixos-generators
    }:
    let
      system = "x86_64-linux";
      stateVersion = "23.05";
      pkgs = import nixpkgs {
        inherit system;

        # Allow unfree packages
        config = {
          allowUnfree = true;
        };
      };

      unstable = import nixpkgs-unstable { inherit system; };

      lib = pkgs.lib;

    in
    {
      packages.${system} = { };
      devShell.${system} = import ./ci/devshell.nix { inherit unstable pkgs; };
    };
}
