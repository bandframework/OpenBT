#!/bin/bash

#
# Build and install the OpenBT C++ library, the standalone command line tools,
# and tests of the library.  These are **not** needed to install and use the
# OpenBT Python package.
#
# Users must pass the path to the folder in which OpenBT should be installed.
#
# ./tools/build_openbt_clt.sh ~/local/OpenBT [--debug]
#
# This script returns exit codes that should make it compatible with use in CI
# build processes.
#
# Intermediate & cached files
# ---------------------------
# This script has Meson create and use the /path/to/OpenBT/builddir folder for
# the build.  Developers can use this script to create that folder and then use
# Meson manually with that folder to develop and test the code.  Users could
# similarly use the contents of the script to guide custom builds.  The Meson
# setup, compile, and install commands in the script might provide a good
# starting point for such efforts.
#
# While the /path/to/OpenBT/subprojects folder does contain necessary files
# under version control, it can also contain cached third-party dependencies
# such as Eigen's source code.  The subprojects/packagecache folder can also
# contain cached files such as third-party dependence tarballs and patches.
# Please note that setting up the Meson build directory with the --clearcache
# flag does **not** remove such files.  Rather, they intentionally persist
# across builds.  Consider reviewing those contents if Meson uses Eigen versions
# or installations different from those intended.
#

#####----- HARDCODED VALUES
use_mpi=true

# Empty means use meson project's default value
warn_level=
#warn_level="--warnlevel 2"

# Empty means use meson project's default value
warnings_as_errors=
#warnings_as_errors="--werror"

#####----- EXTRACT BUILD INFO FROM COMMAND LINE ARGUMENT
if   [[ "$#" -eq 1 ]]; then
    build_type=release
    use_verbose=false
elif [[ "$#" -eq 2 ]]; then
    if [[ $2 != "--debug" ]]; then
        echo
        echo "build_openbt_clt.sh /installation/path [--debug]"
        echo
        exit 1
    fi
    build_type=debug
    use_verbose=true
else
    echo
    echo "build_openbt_clt.sh /installation/path [--debug]"
    echo
    exit 1
fi
prefix=$1

# This should also fail if its a symlink.
if [[ -d $prefix || -f $prefix ]]; then
    echo
    echo "$prefix already exists"
    echo
    exit 1
fi

# ----- SETUP & CHECK ENVIRONMENT
script_path=$(realpath $(dirname -- "${BASH_SOURCE[0]}"))
clone_root=$script_path/..
build_dir=$clone_root/builddir

if ! command -v mpicc &> /dev/null; then
    echo
    echo "Please install MPI with mpicc C compiler wrapper"
    echo
    exit 1
elif ! command -v mpicxx &> /dev/null; then
    echo
    echo "Please install MPI with mpicxx C++ compiler wrapper"
    echo
    exit 1
elif ! command -v meson &> /dev/null; then
    echo
    echo "Please install the Meson build system"
    echo
    exit 1
fi

# ----- LOG IMPORTANT DATA
echo
echo "MPI wrappers"
echo "---------------------------------------------"
which mpicc
mpicc -show
mpicc --version
echo
which mpicxx
mpicxx -show
mpicxx --version
echo

echo
echo "CC=$CC"
echo "CXX=$CXX"
echo "MPICC=$MPICC"
echo "MPICXX=$MPICXX"
echo "CPATH=$CPATH"
echo "CFLAGS=$CFLAGS"
echo "CXXFLAGS=$CXXFLAGS"
echo "CPPFLAGS=$CPPFLAGS"
echo "LDFLAGS=$LDFLAGS"
echo "LIBRARY_PATH=$LIBRARY_PATH"
echo

echo
echo "meson version information"
echo "---------------------------------------------"
which meson
meson --version

# ----- CLEAN-UP LEFTOVERS FROM PREVIOUS BUILDS
echo
echo "Clean-up build environment"
echo "---------------------------------------------"
rm -rf $prefix
rm -rf $build_dir

# ----- SETUP BUILD SYSTEM, CONFIGURE, & BUILD
pushd $clone_root &> /dev/null || exit 1

echo
echo "Configure OpenBT"
echo "---------------------------------------------"
mkdir -p $build_dir                                     || exit 1
meson setup --wipe --clearcache \
    --buildtype=$build_type $build_dir -Dprefix=$prefix \
    $warn_level $warnings_as_errors \
    -Duse_mpi=$use_mpi -Dverbose=$use_verbose -Dpypkg=false || exit 1

echo
echo "Make & Install OpenBT"
echo "---------------------------------------------"
meson compile -v -C $build_dir      || exit 1
meson install --quiet -C $build_dir || exit 1

echo
echo "Test OpenBT Library"
echo "---------------------------------------------"
meson test -C $build_dir || exit 1

popd &> /dev/null
