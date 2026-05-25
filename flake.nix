{
  description = "Lark (飞书国际版) packaged for Nix";

  nixConfig = {
    extra-substituters = [ "https://lark-nix.cachix.org" ];
    extra-trusted-public-keys = [
      # Replace with the actual public key shown on cachix.org after the cache is created.
      # "lark-nix.cachix.org-1:REPLACE_ME"
    ];
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
    in
    {
      packages = forAllSystems (system: rec {
        lark = pkgsFor.${system}.callPackage ./lark.nix { };
        default = lark;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.lark}/bin/bytedance-lark";
        };
      });
    };
}
