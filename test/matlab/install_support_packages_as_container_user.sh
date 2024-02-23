#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with the r2022a release, and a support package installed.
# Support package installation is special, because these packages need to be installed into
# the end users HOME folder and not into the root users folders. Installing into root will
# result in users being unable to access the Support Packages.

# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features matlab   \
#                   --remote-user root \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   `pwd`
# OR:
# devcontainer features test -p `pwd` -f matlab --filter install_support_packages_as_container_user  --log-level debug
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# check <LABEL> <cmd> [args...]

# Verify that the right release is installed in the expected location.
check "r2022a is installed" bash -c "cat /opt/matlab/r2022a/VersionInfo.xml | grep '<release>R2022a</release>'"

# Verify MATLAB_Support_Package_for_Android_Sensors is installed at the right place (ie: The home folder for the containerUser : vscode )
check "support package is installed" bash -c "cat /home/vscode/Documents/MATLAB/SupportPackages/R2022a/ssiSearchFolders | head -1 | grep 'toolbox/matlab/hardware/shared/hwsdk'"

check "python3 is installed " bash -c "python3 --version"

# Verify that MATLAB engine for python is successfully installed
check "MATLAB Engine for python is installed" bash -c "python3 -m pip list | grep -i 'matlabengine'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults