
# How to install matlab-proxy, jupyter-matlab-proxy or the MATLAB Engine for python 3.12?

- The base install.sh script will install PIPX.
- The onCreateCommand lifecycle hook, can then call another script to install python packages using PIPX into a single environment.
- The script will need to be placed into a location that the user can access later on!
    - Assumptions:
        * The script has access to the configuration in the JSON file, so that it knows which packages to install.
        * The script is being run as the end user of the container, only then will the installations by PIPX be visible and on PATH for that user.
        
## How to do it?

- Create a base environment, lets say matlab-proxy
```bash
pipx install matlab-proxy
```
- Then based on other feature requirements, install the others while including their installed apps
```bash
pipx inject --include-apps --include-deps matlab-proxy jupyterlab jupyter-matlab-proxy
```

using pipx would:
1. Make sure that matlab-proxy-app, is on the path.
2. However, generic python packages like matlabengine & jupyter-matlab-proxy will not be available to users

What is the user expectation?
* When the codespace/devcontainer uses the feature:
    a. The environment is already configured with all the things he needs.

* E1: He expects to have the python interpreter setup
* E2: He expects to have matlabengine available for use with the python interpreter that is setup
* E3: If Jupyterlab is available, then he expects to see the MATLAB Integration for Jupyter to show up
* E4: He expects to have the matlab-proxy-app executable available to call

Strategy 1: PIPX to install MP, JMP + Jupyter, ME into a single PIPX MATLAB VENV

Expectations met: E4, E3, E2(only if he uses the notebook)
Expectations failed: E1 & E2

Strategy 2: Strategy 1 + Activate the PIPX MATLAB VENV

NOTES:
* PIPX is a tool to install command line utilities, and not meant for environment management.
* Renaming of environments created using PIPX is directly supported. 
    - one could rename the 


# Attempt 1:
Using the --global flag or equivalent option in PIPX along with ensureonpath as root user.
This allows for the executables to be available for the logged in user.

PIPX is anyways not meant to be a solution for extensibility of packages.

## Behavior
1. executables are found on path by end user.
2. there may be shadowing of executables. ex: mathworks/matlab installs MPA, and that executable sits higher up on the path than the one installed by the devcontainer feature.
3. 

## To Check:
See if the notebook can be used from vscode.

## Issues found:
1. mathworks/matlab:r2025a had issues with user privileges. The mounted repostiory files could not be used.
    * There may be a way to get past this in the devcontainer configuration files.

2. 

## Discoveries
1. MATLAB Engine for Python was able to render the login screens when using `-licmode onlinelicensing`
   The environment was: A Devcontainer running WSL2 on Windows  
# Thoughts

## what are the goals of the devcontainer feature.
* Make it easy to install MATLAB into devcontainers
* Make it easier to use MATLAB in the containerized environment

* What are the ways in which people use MATLAB:
 1. command line
 2. VSCode editor run and edit
 3. Jupyter notebooks in vscode.
 4. Jupyter executable
 5. Desktop MATLAB 
 6. 
