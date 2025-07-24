#!/usr/bin/env bash


MATLAB_PROXY_INSTALL_COMPLETE=0


function is_matlab_proxy_installation_complete() {
    echo "state:$MATLAB_PROXY_INSTALL_COMPLETE"
}

function install_matlab_proxy() {
    MATLAB_PROXY_INSTALL_COMPLETE=1
}

is_matlab_proxy_installation_complete
install_matlab_proxy
is_matlab_proxy_installation_complete


