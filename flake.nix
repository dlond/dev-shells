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
        latexEnv = pkgs.texlive.combined.scheme-medium;

        # --- C/C++ environment ---
        cCppEnvPkgs = with pkgs; [
          clang
          cmake
          conan
          darwin.apple_sdk_min
          lld
          llvmPackages.clang-tools
          llvmPackages.clangd
          llvmPackages.libcxx
          ninja
          pkg-config
        ];
      in {
        devShells = {
          # a single, “all-in-one” shell
          # all = pkgs.mkShell {
          #   name = "all-dev";
          #   buildInputs = pythonEnv :: latexEnv :: cCppEnvPkgs;
          #   shell = "${pkgs.zsh}/bin/zsh";
          #   shellHook = ''
          #     export CPLUS_INCLUDE_PATH="${pkgs.llvmPackages.libcxx}/include/c++/v1:$CPLUS_INCLUDE_PATH"
          #   '';
          # };

          # or pick just one
          python = pkgs.mkShell {
            name = "python-shell";
            buildInputs = pythonEnv;
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
