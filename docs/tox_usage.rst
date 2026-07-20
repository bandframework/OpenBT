.. _developer_env:

Developer Environment
=====================

Tox
---
.. _tox Usage: https://tox.wiki/en/latest/index.html
.. _Oliver Bestwalter: https://youtu.be/PrAyvH-tm8E

Developers are free to setup whatever environment that they may need to
facilitate their work.  However, the |openbt| Python package includes a
`tox Usage`_ setup, which developers can also use to automatically setup and
manage dedicated virtual environments for different predefined development tasks.

Development with |tox|
~~~~~~~~~~~~~~~~~~~~~~

The following is a rough guide to help install |tox| as a command line tool in
a dedicated, minimal virtual environment. |tox| is made available with
no need to manually activate its virtual environment.

.. note::
    Developers that would like to use |tox| should, at the very least, learn
    enough about it that they understand the difference between running ``tox``
    and ``tox -r``.

.. code-block:: console

    $ cd $HOME/local/venv
    $ deactivate
    $ /path/to/desired/python --version
    $ /path/to/desired/python -m venv $HOME/local/venv/.toxbase
    $ ./.toxbase/bin/python -m pip list
    $ ./.toxbase/bin/python -m pip install --upgrade pip setuptools
    $ ./.toxbase/bin/python -m pip install tox
    $ ./.toxbase/bin/python -m pip list
    $ ./.toxbase/bin/tox --version

To avoid having to activate ``.toxbase`` every time we would like to work with
|tox|, we setup |tox| in ``PATH``.  Note that developers can use this single
|tox| installation for multiple projects.  Please replace ``.bash_profile``
with the appropriate shell configuration file and tailor the following to your
needs.

.. code-block:: console

    $ mkdir -p $HOME/local/bin
    $ ln -s $HOME/local/venv/.toxbase/bin/tox $HOME/local/bin/tox
    $ vi $HOME/.bash_profile
    $ . $HOME/.bash_profile
    $ which tox
    $ tox --version

No work will be carried out by default with the calls ``tox`` and ``tox -r``.

Run the following from the directory hierarchy that contains the |openbt|
|tox| configuration file ``/path/to/OpenBT/openbt_pypkg/tox.ini`` to see the
full list of available environments and what each one does:

.. code-block:: console

    $ tox list -v

Environments can be combined in a single invocation, e.g.
``tox -r -e report,coverage``. Users needing ``pdf`` should note that |tox|
does not install ``make`` or a LaTeX distribution; those must be installed
separately.

Direct use of |tox| virtual environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Many of the |tox| tasks will build the |openbt| binary automatically each time
they are run, which can significantly slow development work.  In such cases, a
developer will likely start their work by creating a clean virtual environment
for their task using ``tox -r`` and subsequently load and work in that virtual
environment directly.

Developers can inspect ``tox.ini`` to see what commands are run by their task
and adapt these for their work.

The following example shows how to run only a single test case using the
``coverage`` virtual environment setup by |tox|.

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ tox -r -e coverage
    $ . ./.tox/coverage/bin/activate
    $ which python
    $ python --version
    $ python -m pip list
    $ python -m pytest openbt.tests.test_brt

Note that using the ``coverage`` virtual environment directly can be
particularly useful since the package is installed in editable mode and
therefore facilitates interactive development and testing of the Python code.

The ``html`` environment can be activated directly in the same way to rebuild
documentation iteratively without paying the cost of a full |tox| rebuild each
time:

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ tox -r -e html
    $ . ./.tox/html/bin/activate
    $ which sphinx-build
    $ sphinx-build -W -E -b html ../docs ../docs/build_html

Eigen
-----
.. _Eigen: https://gitlab.com/libeigen/eigen

Eigen_ is a header-only C++ template library for linear algebra.  Being
header-only means there is no compiled library to link against, it is used
purely by including its headers directly into source files.

Installation
~~~~~~~~~~~~

Eigen does not need to be installed manually.  The |openbt| Meson build system
handles Eigen automatically in two steps.  First, Meson searches for an
existing system-wide Eigen installation discoverable |via| ``pkg-config``.  If
found, that installation is used for the build.  If not found, Meson falls back
to the ``subprojects/eigen.wrap`` file, which instructs it to download a
pinned Eigen version automatically from GitLab and use it internally for that
build.  As a result, Eigen is always available to the build regardless of
whether it is installed on the system.

Developers on macOS who prefer to have a system-wide installation can install
Eigen |via| Homebrew:

.. code-block:: console

    $ brew install eigen


Meson Build
-----------
.. _Meson: https://mesonbuild.com
.. _ninja: https://ninja-build.org

The |openbt| Python package uses the Meson_ build system together with its
ninja_ backend to compile the C++ command line tools during installation.
Meson must be installed and available on ``PATH`` before building the package.
Please refer to :ref:`get_started_cpp:Meson installation` for detailed
installation instructions.

Build Process with Python
~~~~~~~~~~~~~~~~~~~~~~~~~

The Meson build is not invoked directly by developers.  It is triggered
automatically when the |openbt| Python package is installed |via|

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ python -m pip install .

or in editable mode |via|

.. code-block:: console

    $ python -m pip install -e .

Internally, ``setup.py`` defines a custom ``build_clt`` command that wipes and
rebuilds ``cpp/builddir`` from scratch on every install, forcing Meson to
re-detect the compiler, MPI, and Eigen installations rather than reusing
stale detection results. Developers who need the exact Meson invocation can
inspect ``build_clt`` in ``setup.py`` directly.

Files and Directories Created
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A successful ``pip install`` creates the following files and directories:

* ``openbt_pypkg/cpp/builddir/`` — Meson's working build directory.  Ninja
  compiles all C++ source files into object files.  This directory is wiped and recreated on
  every ``pip install`` and can be deleted safely at any time.

* ``openbt_pypkg/src/openbt/bin/`` — The compiled C++ command line tools
  installed by ``meson install``.  Only a subset of these are included in the
  distributed package; the rest are still compiled and installed to disk.
  See ``cpp/meson.build`` for the current list of built tools.

* ``openbt_pypkg/src/openbt/include/eigen3/`` — Eigen headers installed
  under the package prefix as a side effect of Eigen's own Meson install
  step, regardless of whether Eigen came from the system or the bundled
  ``subprojects/eigen.wrap``.

* ``openbt_pypkg/src/openbt/lib/pkgconfig/eigen3.pc`` — A ``pkg-config``
  file for the installed Eigen, with its ``prefix`` pointing into
  ``src/openbt/``.

* ``openbt_pypkg/src/openbt/_version.py`` — Written by ``setuptools_scm``
  from the current git tag, not by Meson.

Caching
~~~~~~~

There are four caching layers involved in the build, each with different
behaviour on a recompile:

* ``subprojects/packagecache/`` — Stores the downloaded Eigen tarball and its
  patch so that Meson does not re-download them on every build.
  ``--clearcache`` does not clear this directory; it persists intentionally
  across builds.

* ``cpp/builddir/`` — Ninja's compile cache of object files.  Because
  ``meson setup --wipe`` is run on every ``pip install``, this cache is never
  reused between installs and is always rebuilt from scratch.

* ``src/openbt/{bin,include,lib}/`` — The install destination written by
  ``meson install``.  This is the most problematic caching layer: ``meson
  install`` overlays new files onto these directories but never removes
  stale ones.  If a binary is renamed, a tool is removed from the build, or
  Eigen headers change, the old files persist silently.  When the build
  produces unexpected behaviour, these directories should be deleted manually
  before reinstalling:

  .. code-block:: console

      $ rm -rf openbt_pypkg/src/openbt/bin/
      $ rm -rf openbt_pypkg/src/openbt/include/
      $ rm -rf openbt_pypkg/src/openbt/lib/

* ``openbt_pypkg/.tox/`` — |tox| virtual environments each contain their own
  installed copy of the |openbt| package and compiled binaries.  Running
  ``tox`` without ``-r`` reuses the existing environment and does not
  reinstall |openbt| or rerun the Meson build.  Running ``tox -r`` forces a
  clean environment rebuild and a full ``pip install`` from scratch.