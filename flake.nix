{
  description = "Configuration du nouveau serveur Monalisa";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;

    monalisa-system = "x86_64-linux";

    # Utility function from deploy-rs to create a NixOS deployment configuration
    activateNixos = inputs.deploy-rs.lib."${monalisa-system}".activate.nixos;

    pkgs' = system: nixpkgs:
      import nixpkgs {
        system = system;
        overlays = builtins.attrValues self.overlays;
        config.allowUnfree = false;
      };

    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];

    forEachSystem = lib.genAttrs supportedSystems;
  in {
    overlays = {
      our-packages = final: prev: {
        cedille-mirror = prev.callPackage ./pkgs/cedille-mirror {};
        ftpsync = prev.callPackage ./pkgs/ftpsync {};
      };
    };

    packages = forEachSystem (x:
      with (pkgs' x nixpkgs); {
        inherit cedille-mirror ftpsync;
      });

    formatter = forEachSystem (system: (pkgs' system nixpkgs).alejandra);

    nixosConfigurations = {
      monalisa = lib.nixosSystem {
        system = monalisa-system;
        modules = [
          ./hosts/monalisa/configuration.nix
          ./hosts/monalisa/hardware-configuration.nix
          ./hosts/monalisa/users.nix
          ./hosts/monalisa/headless.nix
          ./hosts/monalisa/networking.nix
          ./hosts/monalisa/mirror.nix
          ./modules/mirror.nix
        ];
        specialArgs = {
          inherit (inputs) self;
          inherit inputs;
        };
        pkgs = pkgs' monalisa-system nixpkgs;
      };
    };

    deploy.nodes.monalisa-mirror = {
      sshOpts = ["-p" "22"];
      hostname = "mirror.monalisa.cedille.club";
      # Whether the user will upload the locally built config remotely
      # If set to false, the remote machine will download the required
      # files from the list of substituers configured on the host
      # (By default: cache.nixos.org)
      fastConnection = false;

      profilesOrder = ["system"];

      # Definition of our system configuration for this node
      profiles.system = {
        sshUser = "automation";
        # User to sudo into
        user = "root";
        path = activateNixos self.nixosConfigurations.monalisa;
      };
    };

    devShell = forEachSystem (system: let
      pkgs = pkgs' system inputs.nixpkgs;
      pkgsUnstable = pkgs' system inputs.nixpkgs-unstable;
    in
      pkgs.mkShell {
        name = "mirror-nixos";
        buildInputs = [
          inputs.sops-nix.packages.${system}.sops-import-keys-hook
          inputs.deploy-rs.defaultPackage.${system}
          pkgs.sops
          pkgsUnstable.terraform_1_0
        ];
      });
  };
}
