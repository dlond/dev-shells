{
  description = "Reusable development shells (Python, LaTeX, C/C++)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # --- Python environment ---
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [numpy pandas scipy matplotlib ipython black ruff]);

        # --- LaTeX environment ---
        latexEnv = pkgs.texlive.combined.scheme-full;

        # --- C/C++ environment ---
        cCppEnvPkgs = with pkgs; [
          apple-sdk
          llvmPackages.clang-unwrapped
          llvmPackages.lld
          llvmPackages.libcxx.dev
          llvmPackages.clang-tools

          cmake
          conan
          ninja
          pkg-config
        ];
      in {
        devShells = {
          python = pkgs.mkShell {
            name = "python-shell";
            buildInputs = [pythonEnv];
            shell = "${pkgs.zsh}/bin/zsh";
          };

          latex = pkgs.mkShell {
            name = "latex-shell";
            buildInputs = [latexEnv pkgs.chktex];
            shell = "${pkgs.zsh}/bin/zsh";
          };

          c-cpp = pkgs.mkShell {
            name = "c-cpp-shell";
            buildInputs = cCppEnvPkgs;
            shell = "${pkgs.zsh}/bin/zsh";
          };
        };
      }
    );
}
