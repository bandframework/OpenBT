.. _developer_env:

Developer Environment
=====================

This section is a repository of information that might be potentially useful to
developers.  Note that information regarding intermediate files/caches that are
created automatically, which might cause issues during development and testing,
is split across sections.

Eigen
-----
.. _Eigen: https://gitlab.com/libeigen/eigen

Eigen_ is a header-only C++ template library for linear algebra.  Being
header-only means there is no compiled library to link against, it is used
purely by including its headers directly into source files.

Installation
~~~~~~~~~~~~

The |openbt| Meson build system satisfies the Eigen dependence automatically.
First, Meson uses different techniques to search for an existing Eigen
installation.  If found, that installation is used for the build.  If not found,
Meson falls back to the ``subprojects/eigen.wrap`` file, which instructs it to
download a pinned Eigen version automatically from Eigen's repository and use it
internally for that build.  As a result, Eigen is always available to the build
regardless of whether it is preinstalled on the system.

Developers using macOS who need to test the build system or who prefer to have a
system-wide installation can install Eigen |via| Homebrew:

.. code-block:: console

    $ brew install eigen

Meson Build
-----------
.. _Meson: https://mesonbuild.com
.. _ninja: https://ninja-build.org

The |openbt| Python package uses the Meson_ build system together with its
ninja_ backend to compile the C++ command line tools during installation.
Please refer to the relevant installation instructions to determine if manual
installation of these tools is required for a particular task.

Please refer to the documentation in ``tools/build_openbt_clt.sh`` script for
information about using that script, for an example of how to configure and use
the Meson build system, and for potential build difficulties (|eg| due to
intermediate and cached files).

Build Process with Python
~~~~~~~~~~~~~~~~~~~~~~~~~

The Meson build is not invoked directly by developers working on or testing the
Python package.  The build is triggered automatically when the |openbt| Python
package is installed |via|

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ python -m pip install .

or in editable mode |via|

.. code-block:: console

    $ python -m pip install -e .

It is also invoked automatically to build wheels.  We generally refer to this
automated process as a "package build."

Internally, ``setup.py`` defines a custom ``build_clt`` command that wipes and
rebuilds the Meson build directory ``openbt_pypkg/cpp/builddir`` from scratch on
every package build, forcing Meson to re-detect the compiler, MPI, and Eigen
installations rather than reusing stale detection results. Developers who need
the exact Meson invocation can inspect ``build_clt`` in ``setup.py`` directly.

A successful package build creates the following files and directories:

* ``openbt_pypkg/cpp/builddir/`` — Meson's working build directory.  Build
  output including object files are stored here.  Since this directory is wiped
  and recreated on every package build, it can be deleted safely at any time.

* ``openbt_pypkg/src/openbt/_version.py`` — Written by ``setuptools_scm``
  from the current git tag, not by Meson.

Note that while ``openbt_pypkg/cpp`` officially contains the package's C++
source code and Meson build system, its contents simply alias the actual code
and build system defined at the root of the repository.  Therefore, for example,
all intermediate and cached issues associated with the base folder also exist
for package builds.

Tox
---
.. _tox setup: https://tox.wiki/en/latest/index.html

Developers are free to setup whatever environment that they may need to
facilitate their work with the Python package.  However, the package includes a
`tox setup`_, which developers can also use to automatically setup and manage
dedicated virtual environments for different predefined development tasks.  Some
tasks are more broadly useful at the level of the whole repository since they
can, for instance, build the User Guides for all |openbt| tools.

Development with |tox|
~~~~~~~~~~~~~~~~~~~~~~

The following is a rough guide to help install |tox| as a command line tool in
a dedicated, minimal virtual environment. |tox| is made available with
no need to manually activate its virtual environment.

.. note::
    Developers that would like to use |tox| should, at the very least, learn
    enough about it that they understand the difference between running ``tox``
    and ``tox -r``.  Some potential issues are highlighted below.

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
    $ vi $HOME/.bash_profile (add $HOME/local/bin to PATH)
    $ . $HOME/.bash_profile
    $ which tox
    $ tox --version

No work will be carried out by default with the calls ``tox`` and ``tox -r``.

Run the following from the directory hierarchy that contains the |openbt|
|tox| configuration file ``/path/to/OpenBT/openbt_pypkg/tox.ini`` to see the
full list of available environments and what each one does:

.. code-block:: console

    $ tox list -v

Two or more tasks can be executed in a single invocation, (|eg| ``tox -r -e
report,coverage``). Users needing ``pdf`` should note that |tox| does not
install ``make`` or a LaTeX distribution; those must be installed separately.

The |tox| tool caches all of its virtual environments in ``openbt_pypkg/.tox/``.
Running ``tox -r <task>`` forces a clean environment rebuild including
installation of (potentially more modern) dependencies and a full package build
from scratch.  Happily, developers can activate and work directly in |tox|'s
cached virtual environments.

Direct use of |tox| virtual environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Many of the |tox| tasks will build the |openbt| binary automatically each time
they are run, which can significantly slow development work.  In such cases,
developer productivity can benefit from creating a clean virtual environment for
their task using ``tox -r <task>`` and subsequently loading and working in that
virtual environment directly.

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
documentation iteratively without paying the cost of a full package rebuild each
time:

.. code-block:: console

    $ cd /path/to/OpenBT/openbt_pypkg
    $ tox -r -e html
    $ . ./.tox/html/bin/activate
    $ which sphinx-build
    $ sphinx-build -W -E -b html ../docs ../docs/build_html

Caching
~~~~~~~
Tox tasks that build the |openbt| package in editable mode install build
products, such as the command line tools, directly in a developer's clone rather
than caching them inside the task's ``openbt_pypkg/.tox/<task>`` folder.  These
cached files,  which can occasionally cause issues, are

* ``openbt_pypkg/src/openbt/{bin,include,lib}/`` — The install destination
  populated by ``meson install``.  This is the most problematic caching layer:
  ``meson install`` overlays new files onto these directories but never removes
  stale ones.  If a binary is renamed, a tool is removed from the build, or
  Eigen headers change, the old files persist silently.  Consider deleting these
  if the build produces unexpected behaviour.  Note that, of these contents,
  only a subset of the command line tools in ``bin`` is included in a package
  build.  See ``meson.build`` for the current list of built tools.

* ``openbt_pypkg/src/openbt/include/eigen3/`` — Eigen headers installed
  under the package prefix as a side effect of Eigen's own Meson install step,
  regardless of whether Eigen came from the system or the bundled
  ``subprojects/eigen.wrap``.  These files are uninmportant once the command
  line tools are built and are not included in package distributions.

* ``openbt_pypkg/src/openbt/lib/pkgconfig/eigen3.pc`` — A ``pkg-config``
  file for the installed Eigen, with its ``prefix`` pointing into
  ``src/openbt/``, that is installed as a side effect.  This file is unimportant
  and is not included in package distributions.
