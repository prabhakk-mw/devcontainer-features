# MATLAB Feature for Development Containers


This repository contains the MATLAB&reg; [Feature](https://github.com/devcontainers/features/) for using MATLAB in development containers. To get started, see [Run MATLAB in Github&trade; Codespaces](https://github.com/mathworks-ref-arch/matlab-codespaces). 

### `matlab`

The MATLAB Feature installs MATLAB, Simulink&reg;, and other MathWorks&trade; products or support packages into a dev container using [`MATLAB Package Manager`](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md). For example, to install MATLAB `R2024a` with Symbolic Math Toolbox in a `ubuntu` base image, use this `devcontainer.json` configuration:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/mathworks/devcontainer-features/matlab:0": {
            "release": "r2024a",
            "products": "MATLAB Symbolic_Math_Toolbox"
        }
    }
}
```

To confirm MATLAB is installed, run:

```bash
$ which matlab
/opt/matlab/r2024a/bin/matlab
```

----

Copyright 2021-2024 The MathWorks, Inc.

----