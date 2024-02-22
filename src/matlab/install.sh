#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
# NOTE: The 'install.sh' entrypoint script is always executed as the root user.

set -eu -o pipefail
# exits on an error (-e, equivalent to -o errexit);
# exits on an undefined variable (-u, equivalent to -o nounset);
# exits on an error in piped-together commands (-o pipefail)

# Uncomment to debug:
# set -x
# Or, set environment variable "SHELLOPTS=xtrace" before starting script

### Variable Declaration Begin ###

## Set defaults to all the options in the feature.

# r2023b is the latest available release.
RELEASE="${RELEASE:-"r2023b"}"
OS="${OS:-"ubuntu22.04"}"
PRODUCTS="${PRODUCTS:-"MATLAB"}"
DOC="${DOC:-"false"}"
INSTALLGPU="${INSTALLGPU:-"false"}"
DESTINATION="${DESTINATION:-"/opt/matlab/${RELEASE}"}"
INSTALLMATLABPROXY="${INSTALLMATLABPROXY:-"false"}"
INSTALLJUPYTERMATLABPROXY="${INSTALLJUPYTERMATLABPROXY:-"false"}"
INSTALLMATLABENGINEFORPYTHON="${INSTALLMATLABENGINEFORPYTHON:-"false"}"
STARTINDESKTOP="${STARTINDESKTOP:-"false"}"
NETWORKLICENSEMANAGER="${NETWORKLICENSEMANAGER:-" "}"
SKIPMATLABINSTALL="${SKIPMATLABINSTALL:-"false"}"

MATLAB_RELEASE="${RELEASE}"
MATLAB_PRODUCT_LIST="${PRODUCTS}"
MATLAB_INSTALL_LOCATION="${DESTINATION}"

### Variable Declaration End ###
### Helper Functions Begin ###

function updaterc() {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >>/etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >>/etc/zsh/zshrc
    fi
}

function install_python_and_xvfb() {
    export DEBIAN_FRONTEND=noninteractive && apt-get update &&
    apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    xvfb &&
    apt-get clean &&
    apt-get -y autoremove && rm -rf /var/lib/apt/lists/*
}

function install_matlab_proxy() {
    install_python_and_xvfb &&
    python3 -m pip install --upgrade matlab-proxy
}

function install_jupyter_matlab_proxy() {
    install_python_and_xvfb &&
    python3 -m pip install --upgrade jupyter-matlab-proxy matlab-proxy jupyterlab jupyterlab-git
}

function install_matlab_engine_for_python() {
    # Installing the engine is tricky
    # The installation can fail if the python version does not match the supported release
    declare -A matlabengine_map
    matlabengine_map['r2023b']="23.2"
    matlabengine_map['r2023a']="9.14"
    matlabengine_map['r2022b']="9.13"
    matlabengine_map['r2022a']="9.12"
    matlabengine_map['r2021b']="9.11"
    matlabengine_map['r2021a']="9.10"
    matlabengine_map['r2020b']="9.9"
    
    export DEBIAN_FRONTEND=noninteractive && apt-get update &&
    apt-get install --no-install-recommends -y \
    python3 \
    python3-pip &&
    apt-get clean &&
    apt-get -y autoremove &&
    rm -rf /var/lib/apt/lists/* &&
    python3 -m pip install matlabengine==${matlabengine_map[$MATLAB_RELEASE]} || true
}

### Helper Functions End ###
### Script Section Begin ###

## Handle all other options first before attempting to install MATLAB.

MATLAB_FEATURE_INSTALL_TMPDIR=/tmp/matlab-feature-install
mkdir -p $MATLAB_FEATURE_INSTALL_TMPDIR && pushd $MATLAB_FEATURE_INSTALL_TMPDIR

# Install matlab-proxy if requested
if [ "${INSTALLMATLABPROXY}" == "true" ]; then
    echo "Installing matlab-proxy"
    install_matlab_proxy
fi

# Install jupyter-matlab-proxy if requested
if [ "${INSTALLJUPYTERMATLABPROXY}" == "true" ]; then
    echo "Installing jupyter-matlab-proxy"
    install_jupyter_matlab_proxy
fi

if [ "${STARTINDESKTOP}" == "true" ] || [ "${STARTINDESKTOP}" == "test" ]; then
    echo "User wants to start in MATLAB Desktop."
    # Leave a marker file that can be checked by the postStartCommand
    # matlab-proxy will be started by the postStartCommand.
    # Current postStartCommand:
    # "( ls ~/.startmatlabdesktop >> /dev/null 2>&1 && env MWI_APP_PORT=8888 matlab-proxy-app 2>/dev/null ) || echo 'Will not start matlab-proxy-app...'",
    # the /tmp directory is not available on codespaces, using _CONTAINER_USER_HOME instead.
    if [ ! -z "${_CONTAINER_USER_HOME}" -a "${_CONTAINER_USER_HOME}" != " " ]; then
        # This feature is only available when _CONTAINER_USER_HOME is known.
        if [ "${STARTINDESKTOP}" == "true" ]; then
            install_matlab_proxy &&
            touch ${_CONTAINER_USER_HOME}/.startmatlabdesktop &&
            chmod a+rw ${_CONTAINER_USER_HOME}/.startmatlabdesktop &&
            rm -f ${_CONTAINER_USER_HOME}/.teststartmatlabdesktop
        else
            # This file is used during testing and does not actually effect the postStartCommand that is looking for
            # the startmatlabdesktop file!
            # Without this, Tests would hang indefinitely waiting for the postStartCommand
            install_matlab_proxy &&
            touch ${_CONTAINER_USER_HOME}/.teststartmatlabdesktop &&
            chmod a+rw ${_CONTAINER_USER_HOME}/.teststartmatlabdesktop &&
            rm -f ${_CONTAINER_USER_HOME}/.startmatlabdesktop
        fi
    else
        echo "Cannot start in desktop as the _CONTAINER_USER_HOME is undefined or empty. Value:'${_CONTAINER_USER_HOME}'"
    fi
fi

# Update RC files with the provided license manager info
if [ ! -z "${NETWORKLICENSEMANAGER}" -a "${NETWORKLICENSEMANAGER}" != " " ]; then
    updaterc "export MLM_LICENSE_FILE=${NETWORKLICENSEMANAGER}"
fi

if [ "$SKIPMATLABINSTALL" != 'true' ]; then
    
    ### MATLAB Installation Steps:
    ## 1. Install OS Dependencies required by MATLAB
    ## 2. Setup MPM flags based on options
    ## 3. Install MATLAB using MPM
    
    ## 1. Install OS Dependencies required by MATLAB
    MATLAB_DEPS_REQUIREMENTS_FILE="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/${OS}/base-dependencies.txt"
    MATLAB_DEPS_REQUIREMENTS_FILE_NAME="/tmp/matlab-deps-${MATLAB_RELEASE}-base-dependencies.txt"
    export DEBIAN_FRONTEND=noninteractive && apt-get update &&
    apt-get install --no-install-recommends -y \
    wget \
    unzip \
    ca-certificates \
    git &&
    wget ${MATLAB_DEPS_REQUIREMENTS_FILE} -O ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} &&
    xargs -a ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} -r apt-get install --no-install-recommends -y &&
    apt-get clean &&
    apt-get -y autoremove &&
    rm -rf /var/lib/apt/lists/* ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME}
    
    ## 2. Setup MPM flags based on options
    ADDITIONAL_MPM_FLAGS=" "
    
    # Handle DOC installation
    if [ "${DOC}" == "true" ]; then
        ADDITIONAL_MPM_FLAGS="${ADDITIONAL_MPM_FLAGS} --doc "
    fi
    
    # Handle GPU installation
    if [ "${INSTALLGPU}" == "false" ]; then
        RELEASES_THAT_SUPPORT_NOGPU=("r2023b" "r2023a")
        # The value variable is assigned a regex that matches the exact value
        value="\<${MATLAB_RELEASE}\>"
        if [[ ${RELEASES_THAT_SUPPORT_NOGPU[@]} =~ $value ]]; then
            echo "'$MATLAB_RELEASE' supports NOGPU flag..."
            ADDITIONAL_MPM_FLAGS="${ADDITIONAL_MPM_FLAGS} --no-gpu "
        else
            echo "'$MATLAB_RELEASE' does not support NOGPU flag, skipping..."
        fi
    fi
    
    echo "Container user is defined as : '$_CONTAINER_USER'"
    echo "Container user's effective home dir: '$_CONTAINER_USER_HOME'"
    echo "Remote user is defined as : '$_REMOTE_USER'"
    echo "Remote user's effective home dir: '$_REMOTE_USER_HOME'"
    
    ## 3. Install MATLAB using MPM
    if [ ! -z "$_CONTAINER_USER" -a "$_CONTAINER_USER" != " " ] && [ "$_CONTAINER_USER" != "root" ]; then
        # Use the containerUser option to set this value. The "vscode" user works well with tests.
        # The "codespaces" user returns an empty _CONTAINER_USER_HOME
        echo "Container user is defined as : '$_CONTAINER_USER'"
        echo "Container user's effective home dir: '$_CONTAINER_USER_HOME'"
        echo "Proceeding to install matlab as '$_CONTAINER_USER'..."
        
        # Switching to container user
        su $_CONTAINER_USER
        pushd $_CONTAINER_USER_HOME
        
        # Installing MATLAB as containerUser allows for support packages to be installed at the correct location.
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm &&
        chmod +x mpm &&
        sudo HOME=${_CONTAINER_USER_HOME} ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${MATLAB_INSTALL_LOCATION} \
        --products ${MATLAB_PRODUCT_LIST} ${ADDITIONAL_MPM_FLAGS} &&
        sudo rm -f mpm /tmp/mathworks_root.log &&
        sudo ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
        
        ## Resetting to original context
        # exit will reset the user to root and call popd
        # exit
        popd
        sudo su
    else
        echo "Proceeding to install matlab as root user..."
        # Installs as root, because feature scripts run as root user.
        # Any support package installed here will not be accessible to non-root users of the system.
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm &&
        chmod +x mpm &&
        ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${MATLAB_INSTALL_LOCATION} \
        --products ${MATLAB_PRODUCT_LIST} ${ADDITIONAL_MPM_FLAGS} &&
        rm -f mpm /tmp/mathworks_root.log &&
        ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
    fi
fi

# MATLAB Engine for Python can only be installed if MATLAB is on the PATH
if [ "${INSTALLMATLABENGINEFORPYTHON}" == "true" ]; then
    echo "Installing matlabengine"
    install_matlab_engine_for_python
fi

popd
### Script Section End ###
echo "MATLAB feature installation is complete."
