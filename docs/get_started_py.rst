Getting Started with Python
===========================
.. _Meson: https://mesonbuild.com
.. _ninja: https://ninja-build.org

Installed versions of the |openbt| Python package contain and wrap a dedicated
set of |openbt| C++ command line tools.  In particular, the package is
hard-coded to use only its internal set of tools.

Typically, nontrivial Python packages are pre-built into binary wheels by
developers so that each wheel is dedicated to a specific operating system and a
particular Python version.  Users install the particular wheel that matches
their setup.  However, |openbt| wheels would also have to be built with respect
to a particular MPI implementation, which is outside of how the Python packaging
system works.  As a result, the software is distributed only as a source
distribution and is built on demand for each case with the compiler suite and
matching MPI implementation provided by the user.

The building of the command line tools is done automatically during the Python
package build/install process by invoking under-the-hood the tools' Meson_ build
system.  While both Meson and its build backend ninja_ are used internally to
build the Python package, they are installed automatically and temporarily just
for building the package.

Dependencies
------------
.. _Eigen: https://gitlab.com/libeigen/eigen
.. _homebrew: https://brew.sh
.. _mpi4py: https://mpi4py.readthedocs.io/en/stable/install.html#wheel-packages

Before building and installing the ``openbt`` Python package, users must provide

* a compiler suite that includes a C++ compiler that supports the C++14
  standard,
* an MPI installation that is compatible with the compiler suite, and
* optionally the Eigen_ software package.

Note that if installing MPI using a package manager, related developer library
packages such as ``libopenmpi-dev`` or ``libmpich-dev`` might need to be
installed in addition to the base MPI packages such as ``openmpi-bin`` or
``mpich``.

Our GitHub actions presently test |openbt| with both Open MPI and MPICH.  In
particular, the actions test the package with these MPI implementations
installed

* |via| package managers such as Ubuntu's Advanced Packaging Tool (``apt``) and
  homebrew_ on macOS as well as
* using |pip| to install Python packages prepared by mpi4py_ that contain a
  single MPI implementation.

In addition, we have successfully run tests manually with the Intel MPI
implementation as installed by experts on a cluster and made available as a
module.

While our set of GitHub actions currently test Anaconda installations, the setup
of those tests within the action runner is less than desirable.  In particular,
the action no longer succeeds to build |openbt| if an MPI implementation is
installed using Conda.  Rather, the action installs an MPI implementation from
PyPI using |pip|, which is less clean than a Conda installation.  Users who
prefer to use Conda should proceed with extra caution.

Install from PyPI
-----------------
.. _project : https://pypi.org/project/openbt

This |openbt| Python package is **not** currently distributed on PyPI since a
PyPI |openbt| project_ already exists.  That PyPI project space will eventually
be transferred to this project so that distribution of this package will be
enabled by PyPI under the name ``openbt``.

Install from clone
------------------
After setting up and activating a virtual environment, users can build and
install the package from a clone of the |openbt| repository by executing

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ python -m pip install .

The package can be installed in developer/editable mode by executing

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ python -m pip install -v -e .

In this latter case, the command line tools are built automatically and
installed at ``/path/to/OpenBT/openbt_pypkg/src/openbt/bin``.

Testing
-------
The |openbt| package contains an integrated test suite, which can be used to
minimally test an installation by executing

.. code-block:: console

    $ python
    >>> import openbt
    >>> openbt.__version__
    '<version>'
    >>> openbt.test()

Of course, users should test their installation and the package further to
confirm that it satisfies their requirements.
