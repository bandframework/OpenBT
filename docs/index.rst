|openbt| Python package
=======================
.. _Open MPI: https://www.open-mpi.org
.. _MPICH: https://www.mpich.org
.. _framework: https://bandframework.github.io

.. todo::
    Write high-level description, explain development history, and motivate
    breakdown of documents presented here.  License, copyright, responsibilities
    of user, etc.

The heart of |openbt| is a set of C++ tools that can be used directly |via| the
command line or indirectly through the ``openbt`` Python package, which wraps
them.  Typically these tools are built with an implementation of the Message
Passing Interface (MPI), such as `Open MPI`_ or MPICH_, to enable distributed
parallelization of computations.  In particular, the Python wrapper package is
always built with MPI support.

The |openbt| software and its distribution scheme have been developed to allow
users to use |openbt| with the MPI installation of their choice.  For instance,
it can be built with MPI installed on a laptop using the system's package
manager or with MPI installations on leadership class platforms and clusters
that were installed by experts and optimized for their specific platform.

.. note::
    While an R wrapper does exist for the original |openbt| and |openbtmixing|
    repositories, that functionality has not yet been included in this new,
    combined repository (Issue #XYZ).

This package is being developed as part of |band| framework_.

.. toctree::
   :numbered:
   :maxdepth: 1
   :caption: C++ User Guide:

   get_started_cpp
   bibliography_cpp

.. toctree::
   :numbered:
   :maxdepth: 1
   :caption: Python User Guide:

   get_started_py
   examples_py
   bibliography_py

.. toctree::
   :numbered:
   :maxdepth: 1
   :caption: Developer Guide:

   contributing
   git_workflow
   documentation
   versioning
   tox_usage
