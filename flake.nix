{
    description = "F-klubben sangbog";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-23.11";
    };

    outputs = { self, nixpkgs }: let
      system = "x86_64-linux";
      pkgs = import nixpkgs {inherit system;};
      deps = with pkgs; [ ghostscript texliveFull psutils gnumake which perl ];
    in {
        devShells.${system}.default = pkgs.mkShell {
            packages = deps;
        };
        packages.${system} = {
            default = pkgs.stdenv.mkDerivation {
                name = "F-klubbens sangbog";
                src = ./.;
                nativeBuildInputs = deps;
                installPhase = ''
                    ${pkgs.gnumake}/bin/make booklet
                    mv main_book.pdf $out
                '';
            };
            pdf = pkgs.stdenv.mkDerivation {
                name = "F-klubbens sangbog pdf";
                src = ./.;
                nativeBuildInputs = deps;
                installPhase = ''
                    ${pkgs.gnumake}/bin/make pdf
                    mv main_book.pdf $out
                '';
            };
        };

    };
}
