#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
#
# Docs:
# Maintainer: The Mathworks, Inc.

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

function install_matlab_proxy () {
    export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    xvfb \
    && apt-get clean \
    && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*
    
    # TODO: verify that matlab-proxy-app is installed into /usr/local/bin
    python3 -m pip install --upgrade matlab-proxy
}

function install_jupyter_matlab_proxy () {
    export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    xvfb \
    && apt-get clean \
    && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*
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
### Helper Functions End ###
### Script Section Begin ###
MATLAB_FEATURE_INSTALL_TMPDIR=/tmp/matlab-feature-install
mkdir -p $MATLAB_FEATURE_INSTALL_TMPDIR && pushd $MATLAB_FEATURE_INSTALL_TMPDIR

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
        ADDITIONAL_MPM_FLAGS=${ADDITIONAL_MPM_FLAGS} --doc
    fi
    
    if [ "${INSTALLGPU}" == "false" ]; then
        ADDITIONAL_MPM_FLAGS=${ADDITIONAL_MPM_FLAGS} --no-gpu
    fi
    
    # Not dealing with support packages at the moment, they will be installed into the root folder
    # and possibly be inaccessible to the end user
    wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \
    chmod +x mpm && \
    ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} && \
    rm -f mpm /tmp/mathworks_root.log && \
    ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab
fi

# Install matlab-proxy if requested
if [ "${INSTALLMATLABPROXY}" == "true" ]; then
    install_matlab_proxy
fi

# Install jupyter-matlab-proxy if requested
if [ "${INSTALLJUPYTERMATLABPROXY}" == "true" ]; then
    install_jupyter_matlab_proxy
fi

# Install MATLAB Engine for Python if requested
if [ "${INSTALLMATLABENGINEFORPYTHON}" == "true" ]; then
    install_matlab_engine_for_python
fi

if [ "${STARTINDESKTOP}" == "true" ]; then
    # Can a feature effect the entrypoint?
    echo "User wants to start matlab-proxy-app by default!"
    install_matlab_proxy
    
    echo "Dont know how to start a process from a feature"
fi

if [ ! -z "${NETWORKLICENSEMANAGER}" -a "${NETWORKLICENSEMANAGER}" != " " ]; then
    updaterc "export MLM_LICENSE_FILE=${NETWORKLICENSEMANAGER}"
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