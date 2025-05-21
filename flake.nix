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
        lib = nixpkgs.lib;

        # --- C/C++ environment ---
        llvmPackage = pkgs.llvmPackages; # dev-shells (this) is responsible for toolchain versioning

        clangCompilerForDriver = llvmPackage.clang-unwrapped;
        clangDriverPath = "${clangCompilerForDriver}/bin/clang++";

        clangMajorVersion = lib.versions.major clangCompilerForDriver.version;
        clangResourceDirInclude = "${clangCompilerForDriver}/lib/clang/${clangMajorVersion}/include";

        hostSysrootPath =
          if pkgs.stdenv.isDarwin
          then pkgs.darwin.apple_sdk.MacOSX-SDK
          else "";

        hostSystemIncludePath =
          if pkgs.stdenv.isDarwin && hostSysrootPath != ""
          then "${hostSysrootPath}/usr/include"
          else "";

        libcxxIncludePath = "${llvmPackage.libcxx.dev}/include/c++/v1";

        cCppEnv = with pkgs; [
          # Build tools
          conan
          cmake
          ninja
          pkg-config

          # Compiler etc from LLVM set
          llvmPackage.clang-unwrapped
          llvmPackage.lld
          llvmPackage.libcxx.dev
          llvmPackage.clang-tools

          # Core C system headers for Darwin
          (lib.optional pkgs.stdenv.isDarwin pkgs.darwin.Libsystem)

          # Darwin SDK
          (lib.optional pkgs.stdenv.isDarwin pkgs.darwin.apple_sdk.MacOSX-SDK)
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
            buildInputs = lib.filter (x: x != null) cCppEnv;
            shell = "${pkgs.zsh}/bin/zsh";
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

        cCppToolchain = {
          inherit clangDriverPath hostSysrootPath hostSystemIncludePath libcxxIncludePath clangResourceDirInclude;
        };
      }
    );
}
