#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright 2025 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------
# NOTE: The 'install-python-package.sh' uses PIPX to install python packages into an environment known

set -eu -o pipefail

function install_python_and_pip() {
    if [ "$(ihf_is_debian_or_rhel)" == "rhel" ]; then
        # uninstalling python3-requests package as it cannot be updated by subsequent install command.
        ihf_remove_packages "python3-requests"
    fi
    ihf_install_packages "python3 python3-pip" && \
    python3 -m pip install --upgrade pip
    
}

function install_xvfb() {
    if [ "$(ihf_is_debian_or_rhel)" == "debian" ]; then
        # Xvfb is unavailable in RHEL systems
        ihf_install_packages "xvfb"
    fi
}

function install_matlab_proxy() {
    install_python_and_pip &&
    install_xvfb &&
    python3 -m pip install --upgrade matlab-proxy
}

function install_jupyter_matlab_proxy() {
    install_python_and_pip &&
    install_xvfb &&
    python3 -m pip install --upgrade jupyter-matlab-proxy matlab-proxy jupyterlab jupyterlab-git
}

function install_matlab_engine_for_python() {
    # Installing the engine is tricky
    # The installation can fail if the python version does not match the supported release
    declare -A matlabengine_map
    matlabengine_map['R2025a']="25.1"
    matlabengine_map['R2024b']="24.2"
    matlabengine_map['R2024a']="24.1"
    matlabengine_map['R2023b']="23.2"
    matlabengine_map['R2023a']="9.14"
    matlabengine_map['R2022b']="9.13"
    matlabengine_map['R2022a']="9.12"
    matlabengine_map['R2021b']="9.11"
    matlabengine_map['R2021a']="9.10"
    matlabengine_map['R2020b']="9.9"
    
    install_python_and_pip &&
    
    echo "Setting LD_LIBRARY_PATH=${_LD_LIBRARY_PATH}"

    env LD_LIBRARY_PATH=${_LD_LIBRARY_PATH} \
    python3 -m pip install  matlabengine==${matlabengine_map[$MATLAB_RELEASE]}.*
}