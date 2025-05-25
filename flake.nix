{
  description = "Reusable development shells (C/C++, Python, LaTeX)";

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

        # --- C/C++ environment ---
        llvmVersion = "llvmPackages";
        llvm = pkgs.${llvmVersion};

        cCppEnv = with pkgs; [
          # Build tools
          conan
          cmake
          ninja
          pkg-config

          # Compiler etc from LLVM set
          llvm.clang
          llvm.clang-tools
          llvm.lld
          llvm.lldb
          llvm.libcxx
          llvm.libcxx.dev
        ];

        # --- Python environment ---
        pythonEnv = pkgs.python3.withPackages (ps:
          with ps; [
            numpy
            pandas
            scipy
            matplotlib
            ipython
            pip
          ]);

        # --- LaTeX environment ---
        latexEnv = pkgs.texlive.combined.scheme-full;
      in {
        devShells = {
          c-cpp = pkgs.mkShell {
            name = "c-cpp-shell";
            buildInputs = [cCppEnv];
            shell = "${pkgs.zsh}/bin/zsh";
            shellHook = ''
              export LLDB_DEBUGSERVER_PATH=/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver
            '';
          };

          python = pkgs.mkShell {
            name = "python-shell";
            buildInputs = [pythonEnv];
            shell = "${pkgs.zsh}/bin/zsh";
          };

          latex = pkgs.mkShell {
            name = "latex-shell";
            buildInputs = [latexEnv];
            shell = "${pkgs.zsh}/bin/zsh";
          };
        };
      }
    );
}
