Getting Started with R
=======================
.. _remotes: https://remotes.r-lib.org

Installed versions of the |openbt| R package, ``Ropenbt``, provide a front-end
R interface that wraps a dedicated set of |openbt| C++ command line tools. 
To build these tools, follow the :doc:`get_started_cpp` guide to build, install,
and test them before continuing.

Install Ropenbt
-------------------------
With the command line tools built, install the
``Ropenbt`` R interface directly from GitHub using the remotes_ package. First, make sure
``remotes`` is installed:

.. code-block:: r

    install.packages("remotes")

Now install ``Ropenbt`` directly from the codebase:

.. code-block:: r

    remotes::install_github(“https://gitub.com/bandframework/OpenBT”, subdir=”Ropenbt”)

Note that some ``Ropenbt`` package dependencies may also be installed. Since
``Ropenbt`` itself needs no compilation, this step is quick regardless of
platform.

See :doc:`examples_r` for a worked example of fitting a model with
``Ropenbt``.