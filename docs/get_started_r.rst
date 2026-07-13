Getting Started with R
=======================
.. _Meson: https://mesonbuild.com
.. _ninja: https://ninja-build.org
.. _remotes: https://remotes.r-lib.org

Installed versions of the |openbt| R package, ``Ropenbt``, provide a front-end
R interface that wraps a dedicated set of |openbt| C++ command line tools. 


Unlike the |openbt| Python package, ``Ropenbt`` does not build or invoke
Meson_ itself. It is a pure R package with no compiled code of its own; it
simply locates and calls the already-built command line tools (such as
``openbtcli``) on the ``PATH``, or in the current working directory as a
fallback. Building those command line tools is a separate, prerequisite step.

Build the C++ command line tools
-----------------------------------------
Before installing ``Ropenbt``, you must first build and install the |openbt|
C++ command line tools using Meson_ and ninja_. Follow the
:doc:`get_started_cpp` guide to

* install the required dependencies (a C++14-compatible compiler, an MPI
  installation, and optionally Eigen_),
* install Meson_ and ninja_, and
* build and install the command line tools.



Install Ropenbt
-------------------------
With the command line tools built, install the
``Ropenbt`` R interface directly from Bitbucket using the remotes_ package. First, make sure
``remotes`` is installed:

.. code-block:: r

    install.packages("remotes")

Now install ``Ropenbt`` directly from Bitbucket:

.. code-block:: r

    remotes::install_bitbucket("mpratola/openbt/Ropenbt")

Note that some ``Ropenbt`` package dependencies may also be installed. Since
``Ropenbt`` itself needs no compilation, this step is quick regardless of
platform.

See :doc:`examples_r` for a worked example of fitting a model with
``Ropenbt``.