# MATLAB® Development Container Features

## Overview

This repository contains a _collection_ of (currently just one) [Feature](https://containers.dev/implementors/features/) for using MATLAB in a [development container](https://containers.dev/).

### `matlab`

Installs MATLAB, Simulink®, and other MathWorks® products or support packages into container via [`mpm`](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md)
```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/mw-gh-integration/devcontainer-features/matlab:0": {
            "release": "r2023b",
            "products": "MATLAB Symbolic_Math_Toolbox"
        }
    }
}
```

```bash
$ which matlab
/opt/matlab/r2023b/bin/matlab
```