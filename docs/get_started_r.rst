Getting Started with R
=======================
.. _remotes: https://remotes.r-lib.org

Installed versions of the |openbt| R package, ``Ropenbt``, provide a front-end R
interface that wraps a dedicated set of |openbt| C++ command line tools.  The
package locates and calls the already-built command line tools (such as
``openbtcli``) by first searching the folders specified in ``PATH``.  If they
are not found, it searches the current working directory as a fallback.

Follow the :doc:`get_started_cpp` guide to build, install, and test the tools
before continuing.

Install Ropenbt
-------------------------
With the command line tools built, install the
``Ropenbt`` R interface directly from GitHub using the remotes_ package. First, make sure
``remotes`` is installed:

.. code-block:: r

    install.packages("remotes")

Now install ``Ropenbt`` directly from the codebase:

.. code-block:: r

    remotes::install_github('https://github.com/bandframework/OpenBT', subdir='Ropenbt')

Note that some ``Ropenbt`` package dependencies may also be installed. Since
``Ropenbt`` itself needs no compilation, this step is quick regardless of
platform.

Testing
-------
The ``Ropenbt`` package does not currently ship a dedicated automated test suite
of its own.  However, executing the full set of steps detailed in
:doc:`examples_r` is a reasonable smoke test that your installation is working
end to end.
