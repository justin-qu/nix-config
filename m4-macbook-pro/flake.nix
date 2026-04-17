{
  description = "A flake template for nix-darwin and Determinate Nix";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    # nixpkgs-unstable is used only for lima; the stable version is outdated and approaching end-of-life.
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      darwinConfigurations.${system} = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit pkgsUnstable; };
        modules = [
          inputs.determinate.darwinModules.default
          self.darwinModules.base
          self.darwinModules.determinateNixConfig
        ];
      };

      darwinModules = {
        base =
          { pkgs, pkgsUnstable, ... }:
          {
            system.stateVersion = 6;

            environment.systemPackages = with pkgs; [
              git
              vim
              htop
              # lima from unstable; stable is outdated and approaching end-of-life
              pkgsUnstable.lima
              # Uncomment to bundle guest agent binaries for both aarch64 and x86_64 VMs:
              # (pkgsUnstable.lima.override { withAdditionalGuestAgents = true; })
              opkssh
            ];

            programs.direnv = {
              enable = true;
              silent = true;
              package = pkgs.direnv.overrideAttrs (_: { doCheck = false; });
            };

            security.pam.services.sudo_local.touchIdAuth = true;

            # See https://nix-darwin.github.io/nix-darwin/manual for all options
          };

        determinateNixConfig =
          { ... }:
          {
            determinateNix = {
              enable = true;

              # To use distributed builds, uncomment and configure build machines:
              # distributedBuilds = true;
              # buildMachines = [ { ... } ];

              # Custom settings written to /etc/nix/nix.custom.conf
              customSettings = {
                eval-cores = 0; # 0 = use all cores
                extra-experimental-features = [
                  "build-time-fetch-tree"
                ];
                trusted-users = [ "@admin" ];
                builders-use-substitutes = true;
                auto-optimise-store = true;
              };

              determinateNixd = {
                garbageCollector.strategy = "automatic";
              };
            };
          };
      };

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          (pkgs.writeShellApplication {
            name = "apply-nix-config";
            runtimeInputs = [ inputs.nix-darwin.packages.${system}.darwin-rebuild ];
            text = ''
              sudo -E darwin-rebuild switch --flake .#${system}
            '';
          })
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
