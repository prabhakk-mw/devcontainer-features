# Development Container Feature for MATLAB

## Overview

This repository contains a [Feature](https://containers.dev/implementors/features/) for using MATLAB in a [development container](https://containers.dev/).

### `matlab`

Installs MATLAB, Simulink®, and other MathWorks® products or support packages into container via [`mpm`](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md)
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

```bash
$ which matlab
/opt/matlab/r2024a/bin/matlab
```