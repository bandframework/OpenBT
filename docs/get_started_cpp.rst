Getting Started with C++
========================
These instructions should be followed by users and developers that would like to
work with the C++ command line tools directly.  All others should follow the
installation instructions of the wrapper package provided for their desired
programming language.

Dependencies
------------
.. _Meson: https://mesonbuild.com
.. _ninja: https://ninja-build.org
.. _Eigen: https://gitlab.com/libeigen/eigen
.. _homebrew: https://brew.sh

Before building and installing C++ command line tools, users must provide

* a compiler suite that includes a C++ compiler that supports the C++14
  standard,
* the Meson_ build system and its prerequisites such as Python 3 and ninja_,
* an MPI installation that is compatible with the compiler suite, and
* optionally the Eigen_ software package.

We presently have a single GitHub action that tests the C++ command line tools
with both Open MPI and MPICH installed |via| Ubuntu's Advanced Packaging Tool
(``apt``) and homebrew_ on macOS.  In addition, we have successfully run tests
manually with the Intel MPI implementation as installed by experts on a cluster
and made available as a module.

Note that if installing MPI using a package manager, related developer library
packages such as ``libopenmpi-dev`` or ``libmpich-dev`` might need to be
installed in addition to the base MPI packages such as ``openmpi-bin`` or
``mpich``.

Meson installation
------------------
The Meson build system documentation suggests installing Meson |via| package
manager when possible.  Please refer to that documentation for detailed and
up-to-date installation information.

If Meson cannot be installed by package manager or the manager's version is too
old, the following is contrary to Meson suggestions but has been used
successfully to install Meson with Python into a dedicated virtual environment
as well as to install ``meson`` in the ``PATH`` for use without needing to
activate that virtual environment.

.. code-block:: bash

    $ /path/to/target/python -m venv ~/local/venv/meson
    $ . ~/local/venv/meson/bin/activate
    $ which python
    $ python -m pip install --upgrade pip
    $ python -m pip install meson
    $ python -m pip list
    $ ln -s ~/local/venv/meson/bin/meson ~/local/bin
    <add ~/local/bin to PATH if desired and appropriate>
    $ deactivate
    $ which meson
    $ meson --version

Note that this ``meson`` virtual environment is for installing **just** the
Meson build system.

Building & Testing
------------------
.. _Issue 7: https://github.com/bandframework/OpenBT/issues/7

|openbt|'s Meson build system is setup to automatically detect the compiler
suite and MPI installation to use.  If Eigen already exists in the system and
Meson can find it, then Meson will use it for the build.  Otherwise, Meson will
automatically obtain a copy of Eigen for internal use.

Developers and C++ users can directly build and install the command line tools,
an |openbt| library, and all related headers with `tools/build_openbt_clt.sh
<https://github.com/bandframework/OpenBT/blob/main/tools/build_openbt_clt.sh>`__.
This script also runs the command line tool test suite and prints test results.
Please read the documentation at the top of the script for more information.

.. note::
    The state and effectiveness of the C++ command line tool test suite is under
    investigation (`Issue 7`_).
