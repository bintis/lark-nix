# lark-nix

[Lark](https://www.larksuite.com/) (飞书国际版) packaged as a Nix flake.

The package wraps the official `.deb` from larksuite.com — same approach as `pkgs.feishu` in nixpkgs, but pointed at the international (Singapore) CDN instead of the mainland China one.

A GitHub Action checks for new Lark releases daily and commits version bumps automatically. Builds are pushed to [Cachix](https://app.cachix.org/cache/lark-nix), so consumers don't have to rebuild the ~1.5 GB closure on every upgrade.

## Usage

Add as a flake input:

```nix
{
  inputs.lark-nix.url = "github:bintis/lark-nix";

  outputs = { self, nixpkgs, lark-nix, ... }: {
    # ... wherever you build home-manager / NixOS config ...
    home.packages = [
      lark-nix.packages.x86_64-linux.lark
    ];
  };
}
```

To pick up upstream Lark updates:

```
nix flake update lark-nix
```

## Cachix

To use the prebuilt binary cache, add to your `flake.nix` `nixConfig` or `/etc/nix/nix.conf`:

```
substituters       = https://lark-nix.cachix.org https://cache.nixos.org
trusted-public-keys = lark-nix.cachix.org-1:<KEY> cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
```

The exact public key is shown on [the cache's page](https://app.cachix.org/cache/lark-nix).

## Supported systems

- `x86_64-linux`

aarch64 .debs are published by Lark too — patches welcome.

## License

The packaging code in this repo is MIT. The Lark binary itself is proprietary; see Lark's terms of service.
