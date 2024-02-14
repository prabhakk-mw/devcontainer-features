#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'matlab' feature with
# "startInDesktop": true,
# "networkLicenseManager": "123@abc.com"

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
# check <LABEL> <cmd> [args...]

check "python3 is installed" python3 --version

check "matlab-proxy has been installed"  bash -c "python3 -m pip list | grep matlab-proxy"

check "matlab-proxy-app is callable" bash -c "matlab-proxy-app -h"

check "is startInDesktop marker file present" bash -c "ls /tmp/.startmatlabdesktop"

check "NLM information is saved in bashrc " bash -c "echo $MLM_LICENSE_FILE | grep 123@abc.com "
# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
