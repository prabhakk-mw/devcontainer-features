#!/usr/bin/env bash
# This script install the OS dependencies required by MATLAB for the release specified in the
# environment variable MATLAB_RELEASE on any linux OS that is dervied from Ubuntu or RHEL
#-------------------------------------------------------------------------------------------------------------
# Copyright 2024 The MathWorks, Inc.
#-------------------------------------------------------------------------------------------------------------

set -eu -o pipefail
# exits on an error (-e, equivalent to -o errexit);
# exits on an undefined variable (-u, equivalent to -o nounset);
# exits on an error in piped-together commands (-o pipefail)

# Uncomment to debug:
# set -x
# Or, set environment variable "SHELLOPTS=xtrace" before starting script

if [ $(basename "$0") != "install-matlab-deps.sh" ]; then
    _SCRIPT_LOCATION="$1"
    source ${_SCRIPT_LOCATION}/install-helper-functions.sh
else
    source $(dirname "$0")/install-helper-functions.sh
fi


# Verify if valid MATLAB_RELEASE
if [ "$(ihf_is_valid_matlab_release)" == "false" ]; then
    ihf_print_and_exit "Invalid or Unsupported MATLAB_RELEASE: $MATLAB_RELEASE "
fi

function print_os_info(){
    . /etc/os-release
    echo "Running install-matlab-deps script on: $PRETTY_NAME"
    echo "ID=$ID , VERSION_ID=$VERSION_ID, for MATLAB_RELEASE=$MATLAB_RELEASE"
}

function get_prerequisite_pkgs() {
    # Returns the list of pre-requisite packages required to install matlab-deps
    echo "wget unzip ca-certificates"
}

function get_base_dependencies_list() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    local BASE_DEPS_URL=https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt
    # Get matlab_deps - if this fails, then we aren't on a supported os
    local PKGS=$(wget -qO- ${BASE_DEPS_URL})
    if [ -z "$PKGS" ]; then
        ihf_print_and_exit "${MATLAB_DEPS_OS_VERSION} is not a supported OS for MATLAB ${MATLAB_RELEASE} ."
    fi
    echo $PKGS
}

function install_matlab_deps() {
    local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
    # local linux_distro=$(ihf_is_debian_or_rhel)
    
    print_os_info
    
    local PREREQ_PACKAGES=$(get_prerequisite_pkgs)
    
    ihf_install_packages "$PREREQ_PACKAGES"
    
    echo "Get list of dependencies from ${MATLAB_RELEASE}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt"
    local BASE_DEPS_PKGS=$(get_base_dependencies_list)
    ihf_install_packages "$BASE_DEPS_PKGS"
    
    ihf_clean_up
    # Return 0 to indicate success!
    return 0
}
install_matlab_deps


# function exit_if_not_successfull() {
#     local LAST_STATUS=$?
#     if [ $LAST_STATUS -ne 0 ]; then
#         echo "Error code $LAST_STATUS found, exiting..."
#         exit $LAST_STATUS
#     fi
# }

# function install_with_apt_get() {
#     # expects the first input argument to hold the list of packages to install
#     echo "Packages to install are: $1"
#     local PKGS_TO_INSTALL="$1"
#     apt-get update &&
#     apt-get install --no-install-recommends --yes ${PKGS_TO_INSTALL} &&
#     apt-get clean &&
#     apt-get autoremove &&
#     rm -rf /var/lib/apt/lists/*
#     exit_if_not_successfull
# }

# function install_with_yum() {
#     echo "Packages to install are: $1"
#     local PKGS_TO_INSTALL="$1"
#     yum update --disableplugin=subscription-manager -y &&
#     yum install --disableplugin=subscription-manager -y ${PKGS_TO_INSTALL} &&
#     yum --disableplugin=subscription-manager clean all -y
# }

# function install_ubuntu() {
#     local MATLAB_DEPS_OS_VERSION=$(ihf_get_matlab_deps_os)
#     echo "Installing matlab-deps for ${MATLAB_DEPS_OS_VERSION}..."
#     local PREREQ_PACKAGES=$(get_prerequisite_pkgs)
#     install_with_apt_get "$PREREQ_PACKAGES"

#     echo "Get list of dependencies from ${MATLAB_RELEASE}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt"
#     local BASE_DEPS_PKGS=$(get_base_dependencies_list)
#     install_with_apt_get "$BASE_DEPS_PKGS"
#     # Return 0 to indicate success!
#     return 0
# }

# function install_rhel() {
#     echo "Installing matlab-deps for ${MATLAB_DEPS_OS_VERSION}..."
#     local PREREQ_PACKAGES=$(get_prerequisite_pkgs)
#     install_with_yum "$PREREQ_PACKAGES"

#     echo "Get list of dependencies from ${MATLAB_RELEASE}/${MATLAB_DEPS_OS_VERSION}/base-dependencies.txt"
#     local BASE_DEPS_PKGS=$(get_base_dependencies_list)
#     install_with_yum "$BASE_DEPS_PKGS"

#     # Return 0 to indicate success!
#     return 0
# }

# linux_distro=$(ihf_is_debian_or_rhel)

# if [ "$linux_distro" == "debian" ]; then
#     install_ubuntu
# fi

# if [[ ${SUPPORTED_IDS[@]} =~ ${ID_REGEX} ]]; then
#     echo "Proceeding with install on supported distribution..."
#     if [ "$ID" == "ubuntu" ] || [ "$ID" == "debian" ]; then
#         install_ubuntu
#         elif [ "$ID" == "rhel" ] || [ "$ID" == "fedora" ]; then
#         install_rhel
#     fi
#     if [ $? -eq 0 ]; then
#         # Install complete
#         exit 0
#     fi
# fi
# print_and_exit "Un-supported distribution ${ID}"
