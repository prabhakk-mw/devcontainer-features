#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------

### Variable Declaration Begin ###

MATLAB_RELEASE="${RELEASE:-"r2023b"}"

# Specify the list of products to install into MATLAB.
MATLAB_PRODUCT_LIST="${PRODUCTS:-"MATLAB"}"

# Specify MATLAB Install Location.
MATLAB_INSTALL_LOCATION="${DESTINATION:-"/opt/matlab/${MATLAB_RELEASE}"}"

OS="${OS:-"ubuntu22.04"}"

### Variable Declaration End ###
### Helper Functions Begin ###

function updaterc() {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/zsh/zshrc
    fi
}

function install_python_and_xvfb () {
    export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    xvfb \
    && apt-get clean \
    && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*
}

function install_matlab_proxy () {
    install_python_and_xvfb && \
    python3 -m pip install --upgrade matlab-proxy
}

function install_jupyter_matlab_proxy () {
    install_python_and_xvfb && \
    python3 -m pip install --upgrade jupyter-matlab-proxy matlab-proxy
}

function install_matlab_engine_for_python () {
    export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y  python3-distutils \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && cd ${MATLAB_INSTALL_LOCATION}/extern/engines/python \
    && python setup.py install || true
}

function install_matlab_as_container_user () {
    # Switching to container user
    su $_CONTAINER_USER
    pushd $_CONTAINER_USER_HOME
    
    # Installing MATLAB as containerUser allows for support packages to be installed at the correct location.
    wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
    && chmod +x mpm \
    && sudo HOME=${_CONTAINER_USER_HOME} ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} ${ADDITIONAL_MPM_FLAGS} \
    && sudo rm -f mpm /tmp/mathworks_root.log \
    && sudo ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
}

### Helper Functions End ###
### Script Section Begin ###

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

# Install MATLAB Engine for Python if requested
if [ "${INSTALLMATLABENGINEFORPYTHON}" == "true" ]; then
    echo "Installing matlabengine"
    install_matlab_engine_for_python
fi

if [ "${STARTINDESKTOP}" == "true" ]; then
    # Can a feature effect the entrypoint?
    echo "User wants to start matlab-proxy-app by default!"
    # Leave a marker file that can be checked by the postStartCommand
    # matlab-proxy will be started by the postStartCommand.
    install_matlab_proxy && \
    touch /tmp/.startmatlabdesktop
fi

if [ ! -z "${NETWORKLICENSEMANAGER}" -a "${NETWORKLICENSEMANAGER}" != " " ]; then
    updaterc "export MLM_LICENSE_FILE=${NETWORKLICENSEMANAGER}"
fi

if [ "$SKIPMATLABINSTALL" != 'true' ]; then
    # Install dependencies for OS
    MATLAB_DEPS_REQUIREMENTS_FILE="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/${OS}/base-dependencies.txt"
    MATLAB_DEPS_REQUIREMENTS_FILE_NAME="/tmp/matlab-deps-${MATLAB_RELEASE}-base-dependencies.txt"
    export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    wget \
    unzip \
    ca-certificates \
    git \
    && wget ${MATLAB_DEPS_REQUIREMENTS_FILE} -O ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} \
    && xargs -a ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} -r apt-get install --no-install-recommends -y \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME}
    
    ADDITIONAL_MPM_FLAGS=" "
    if [ "${DOC}" == "true" ]; then
        ADDITIONAL_MPM_FLAGS="${ADDITIONAL_MPM_FLAGS} --doc "
    fi
    
    if [ "${INSTALLGPU}" == "false" ]; then
        RELEASES_THAT_SUPPORT_NOGPU=("r2023b" "r2023a")
        # The value variable is assigned a regex that matches the exact value
        value="\<${MATLAB_RELEASE}\>"
        if [[ ${RELEASES_THAT_SUPPORT_NOGPU[@]} =~ $value ]]
        then
            echo "'$MATLAB_RELEASE' supports NOGPU flag..."
            ADDITIONAL_MPM_FLAGS="${ADDITIONAL_MPM_FLAGS} --no-gpu "
        else
            echo "'$MATLAB_RELEASE' does not support NOGPU flag, skipping..."
        fi
    fi
    
    if [ ! -z "$_CONTAINER_USER" -a "$_CONTAINER_USER" != " " ] && [ "$_CONTAINER_USER" != "root" ]; then
        echo "Container user is defined as : '$_CONTAINER_USER'"
        echo "Container user's effective home dir: '$_CONTAINER_USER_HOME'"
        
        echo "Proceeding to install matlab as '$_CONTAINER_USER'..."
        
        # Switching to container user
        su $_CONTAINER_USER
        pushd $_CONTAINER_USER_HOME
        
        # Installing MATLAB as containerUser allows for support packages to be installed at the correct location.
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
        && chmod +x mpm \
        && sudo HOME=${_CONTAINER_USER_HOME} ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${MATLAB_INSTALL_LOCATION} \
        --products ${MATLAB_PRODUCT_LIST} ${ADDITIONAL_MPM_FLAGS} \
        && sudo rm -f mpm /tmp/mathworks_root.log \
        && sudo ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
        
        ## Resetting to original context
        # exit will reset the user to root and call popd
        exit
        # popd
        # sudo su
    else
        # Installs as root, because feature scripts run as root user.
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm \
        && chmod +x mpm \
        && ./mpm install \
        --release=${MATLAB_RELEASE} \
        --destination=${MATLAB_INSTALL_LOCATION} \
        --products ${MATLAB_PRODUCT_LIST} ${ADDITIONAL_MPM_FLAGS}\
        && rm -f mpm /tmp/mathworks_root.log \
        && ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
    fi
    
fi

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
# echo "The effective dev container remoteUser is '$_REMOTE_USER'"
# echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

# echo "The effective dev container containerUser is '$_CONTAINER_USER'"
# echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

echo "MATLAB feature installation is complete."

popd
### Script Section End ###