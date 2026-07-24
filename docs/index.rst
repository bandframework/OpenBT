Welcome to |openbt|'s Documentation!
====================================
.. _Open MPI: https://www.open-mpi.org
.. _MPICH: https://www.mpich.org
.. _framework: https://bandframework.github.io
.. _OpenBT repository: https://bitbucket.org/mpratola/openbt/src/master
.. _OpenBTMixing repository: https://github.com/jcyannotty/OpenBT

.. image:: images/openbt_logo_rect.png
    :align: center
    :alt: OpenBT
    :height: 165
    :width: 451

|openbt| is an extensible software project that implements a variety of Bayesian tree models for scientific and industry applications, including regression, model mixing, sensitivity analysis and multiobjective optimization.  

The heart of |openbt| is a set of C++ tools that can be used directly |via| the
command line or indirectly through the ``openbt`` Python package or ``RopenBT`` R package, which wrap
the tools.  Typically these tools are built with an implementation of the Message
Passing Interface (MPI), such as `Open MPI`_ or MPICH_, to enable distributed
parallelization of computations.  In particular, the Python wrapper package is
always built with MPI support.

The |openbt| software and its distribution scheme have been developed to allow
users to use |openbt| with the MPI installation of their choice.  For instance,
it can be built with MPI installed on a laptop using the system's package
manager or with MPI installations on leadership class platforms and clusters
that were installed by experts and optimized for their specific platform.

This repository was established by merging the contents of the original Bitbucket
`OpenBT repository`_ with the `OpenBTMixing repository`_, which was based off of
the former.  It, therefore, will supersede those two repositories, which will be
frozen.

This repository and its contents are being established and developed as part of
|band| framework_.

.. toctree::
   :numbered:
   :maxdepth: 1
   :caption: C++ User Guide:

   get_started_cpp

.. toctree::
   :numbered:
   :maxdepth: 1
   :caption: R User Guide:

   get_started_r
   examples_r

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
   developer_environment
   versioning
   release_procedure
