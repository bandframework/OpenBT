#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo
    echo "install_meson.sh /installation/path {macOS, Linux}"
    echo
    exit 1
fi
install_path=$1
runner_os=$2

# Meson docs suggest installing via package managers, which makes good sense.
# However,
# * versions available through Ubuntu package installation can be quite
#   out-of-date and
# * tests have been failing recently with Meson installs via homebrew.
# So, we follow a different path that they mention of installing via pip.
#
# ninja is already installed in macOS runners.
if   [ "$runner_os" = "Linux" ]; then
    sudo apt-get update
    sudo apt-get -y install ninja-build
elif [ "$runner_os" != "macOS" ]; then
    echo
    echo "Invalid runner OS $runner_os"
    echo
    exit 1
fi

# Create virtual environment
venv_path=$install_path/local/venv
meson_venv=$venv_path/meson
local_bin=$install_path/local/bin

echo "Creating Python virtual environment at $meson_venv"
mkdir -p $venv_path
mkdir -p $local_bin
python -m venv $meson_venv
source $meson_venv/bin/activate

echo "Using Python: $(which python)"
echo "Using pip: $(which pip)"

# Beginning with v1.6.0 meson can automatically find OpenMPI and MPICH
python -m pip install --upgrade pip setuptools
python -m pip install "meson>=1.6.0"

echo "Installed packages:"
python -m pip list
echo " "
echo "Meson version: $(meson --version)"

# Install Meson command in the local bin directory for use in future steps
ln -s $meson_venv/bin/meson $local_bin
echo "$local_bin" >> "$GITHUB_PATH"
