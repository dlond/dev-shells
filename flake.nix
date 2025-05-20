{
  description = "Reusable development shells (Python, LaTeX, C/C++)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # Use flake-utils to easily support common systems
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # --- Python Environment Definition ---
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # Using python3 alias, change to python313 etc. if specific version needed
          numpy
          pandas
          scipy
          matplotlib
          ipython
          pip # Good practice to include pip
          # Add other common tools: black, ruff, pytest, etc. if desired universally
        ]);

        # --- LaTeX Environment Definition ---
        latexEnv = pkgs.texlive.combined.scheme-full; # Full scheme is large but comprehensive
        # Alternatives: scheme-medium, scheme-basic, or specific packages:
        # latexEnv = pkgs.texlive.combine {
        #   inherit (pkgs.texlive) scheme-medium collection-latexrecommended collection-fontsrecommended luatex;
        # };


        # --- C/C++ Environment Definition ---
        # Needs input on specific tools required!
        cCppEnvPkgs = with pkgs; [
          # Core toolchain
          conan
          cmake
          clang
          lld
          ninja

          # C++ standard-library headers and libs
          llvmPackages.libcxx

          # Common utilities
          pkg-config
          llvmPackages.lldb

          # Add libraries if needed universally, e.g. openssl, boost
          # Often, C/C++ libraries are project-specific inputs.
        ];

      in
        {
        # --- Exported Development Shells ---

        devShells = {

          python = pkgs.mkShell {
            name = "python-shell";
            buildInputs = [ pythonEnv ];
            shell = "${pkgs.zsh}/bin/zsh";
            shellHook = ''
              # Set VIRTUAL_ENV for prompt or tools recognizing it (optional)
              export VIRTUAL_ENV="$PWD/.nix-python-env"
              # Do NOT manipulate PATH here for buildInputs.
              echo "Activated Nix Python environment from dev-shells flake."
              # You could add more hooks, e.g. unset VIRTUAL_ENV on exit
              '';
          };

          latex = pkgs.mkShell {
            name = "latex-shell";
            buildInputs = [ latexEnv pkgs.chktex ]; # Add chktex or other tools
            shell = "${pkgs.zsh}/bin/zsh";
            shellHook = ''
              echo "Activated Nix LaTeX environment from dev-shells flake."
              '';
          };

          c-cpp = pkgs.mkShell {
            name = "c-cpp-shell";
            buildInputs = cCppEnvPkgs;
            shell = "${pkgs.zsh}/bin/zsh";
              shellHook = ''
                # C++ stdlib
                export CPLUS_INCLUDE_PATH="${pkgs.llvmPackages.libcxx}/include/c++/v1:$CPLUS_INCLUDE_PATH"
                # C system headers (libSystem-B)
                export C_INCLUDE_PATH="${pkgs.libSystem}/include:$C_INCLUDE_PATH"
                echo "Activated Nix C/C++ environment from dev-shells flake."
              '';
            # Add env vars if needed, e.g. for include paths, though pkg-config helps
          };

        }; # End devShells

      } # End per-system outputs
    ); # End flake-utils.lib.eachDefaultSystem
}
