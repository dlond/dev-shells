# My Reusable Nix Development Environments (dev-shells)

This repository provides reproducible, declarative, and ephemeral development environments using [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Purpose

Instead of defining development environments from scratch in every project, this flake provides pre-configured, reusable shells for common languages and tasks. Projects can use this flake as an input to easily access these consistent environments.

## Available Shells

Currently defined shells (accessible via `devShells.<system>.<name>`):

* `python`: Standard Python 3 environment with common data science libraries (numpy, pandas, etc.) and pip.
* `c-cpp`: C/C++ environment with Clang, Conan, CMake, and Ninja.
* `latex`: A full TeX Live environment for LaTeX document preparation.
* *(Add more as you define them)*

## Usage: Setting Up a New Project

To use one of these shells in a new project (e.g., `my-new-project` wanting the Python shell):

1.  **Create Project Directory:**
    ```bash
    mkdir my-new-project
    cd my-new-project
    ```

2.  **Initialize Git (Recommended):**
    ```bash
    git init
    ```

3.  **Create Project `flake.nix`:**
    Create a file named `flake.nix` in the root of `my-new-project` with the following content. **Make sure to replace `<your-username>` with your actual GitHub username!**

    ```nix
    # my-new-project/flake.nix
    {
      description = "My new project using a standard Python dev shell";

      inputs = {
        # Standard Nix packages collection
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

        # Input for the reusable development shells
        # !! REPLACE <your-username> !!
        dev-shells.url = "github:<your-username>/dev-shells";
        # Optional but recommended: Ensure dev-shells uses the same nixpkgs
        dev-shells.inputs.nixpkgs.follows = "nixpkgs";

        # Utility for multi-system support (optional but good practice)
        flake-utils.url = "github:numtide/flake-utils";
      };

      outputs = { self, nixpkgs, dev-shells, flake-utils }:
        # Use flake-utils to define outputs for common systems
        flake-utils.lib.eachDefaultSystem (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            # Define the default development shell for `nix develop` or `direnv`
            devShells.default =
              # Select the desired shell from the dev-shells input
              dev-shells.devShells.${system}.python;

            # --- Optional: Adding project-specific packages ---
            # If you need packages beyond the base python shell:
            /*
            devShells.default = pkgs.mkShell {
              name = "my-project-python-shell";
              # Inherit everything from the base python shell
              inputsFrom = [ dev-shells.devShells.${system}.python ];
              # Add packages specific to this project
              packages = [ pkgs.requests ];
              # You can also add shellHooks etc. here
            };
            */

            # --- Optional: Using a different shell ---
            # If this was a C++ project instead:
            # devShells.default = dev-shells.devShells.${system}.c-cpp;

          }
        );
    }
    ```

4.  **Create `.envrc` file:**
    Create a file named `.envrc` in the root of `my-new-project` with this single line:
    ```bash
    use flake
    ```
    *(This tells `direnv` to load the `devShells.default` from the `flake.nix` in this directory).*

5.  **Activate the Environment:**
    * If this is the first time `direnv` sees this `.envrc`, you'll need to allow it:
        ```bash
        direnv allow .
        ```
    * Otherwise, `direnv` should automatically load the environment when you `cd` into the `my-new-project` directory. You should see the activation message defined in the `dev-shells` flake's shell hook.

You now have the reproducible development environment ready for your project!

## Updating Shells

If the `dev-shells` repository is updated (e.g., new tools added to the Python shell), you can update your project to use the latest version by running this command *inside your project directory* (`my-new-project`):

```bash
nix flake update dev-shells
