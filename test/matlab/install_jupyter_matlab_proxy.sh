#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with "installJupyterMatlabProxy": "true" option.

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
#

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.

# Check if python3 is installed
check "python3 is installed" python3 --version

check "jupyter-matlab-proxy has been installed"  bash -c "python3 -m pip list | grep jupyter-matlab-proxy"

check "matlab-proxy has been installed"  bash -c "python3 -m pip list | grep matlab-proxy"

check "matlab-proxy-app is callable" bash -c "matlab-proxy-app -h"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults