
# MATLAB (matlab)

Installs MATLAB with supporting packages and tools.

## Example Usage

```json
"features": {
    "ghcr.io/prabhakk-mw/devcontainer-features/matlab:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| release | MATLAB Release to install. | string | R2025b |
| products | Products to install, specified as a list of space-separated product names.</br> For details, see [Input Arguments to MATLAB Package Manager](https://mathworks.com/help/install/ug/mpminstall.html#mw_982f28f7-dc9f-482e-83c7-63c46ad9126f). | string | MATLAB |
| doc | Flag to install documentation and examples (R2022b and earlier releases). | boolean | false |
| installGpu | Skips installation of GPU libraries when you install Parallel Computing Toolbox (R2023a and later releases). | boolean | false |
| destination | Full path to the installation destination folder. Default: /opt/matlab/${RELEASE^} | string | - |
| installMatlabProxy | Installs matlab-proxy and its dependencies (R2020b and later releases). | boolean | false |
| installJupyterMatlabProxy | Installs jupyter-matlab-proxy and its dependencies (R2020b and later releases). | boolean | false |
| installJupyterLab | Installs jupyterlab | boolean | false |
| installMatlabEngineForPython | Installs the MATLAB Engine for Python if the destination option is set correctly. | boolean | false |
| startInDesktop | Starts matlab-proxy when container starts. | string | false |
| networkLicenseManager | MATLAB will use the specified Network License Manager. | string | - |
| skipMATLABInstall | Set to true if you do not want to install MATLAB, for example if you only want to install `matlab-proxy` or `jupyter-matlab-proxy`. | boolean | false |
| enableTelemetry | Set to false to disable telemetry that helps improve this feature. For more information, See: [User Experience Information FAQ](https://mathworks.com/support/faq/user_experience_information_faq.html) | boolean | true |

## Customizations

### VS Code Extensions

- `MathWorks.language-matlab`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/prabhakk-mw/devcontainer-features/blob/main/src/matlab/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
