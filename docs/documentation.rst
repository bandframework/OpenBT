Documentation
=============

Tools
-----
.. _`typos`: https://github.com/crate-ci/typos
.. _`lychee`: https://lychee.cli.rs

A GitHub action is run automatically to check for typographic errors in all
documentation in the repository using the typos_ tool with our ``typos.toml``
configuration file.  An associated ``typos`` command line tool can also be
installed locally by developers for checking eagerly for mistakes:

.. code:: console

    $ cd /path/to/OpenBT
    $ typos --config=typos.toml

Another GitHub action automatically checks the documentation for broken links
using the tool lychee_ and its ``.lycheeignore`` configuration file.  An
associated ``lychee`` command line tool can also be installed locally by
developers for checking eagerly for mistakes:

.. code:: console

    $ cd /path/to/OpenBT
    $ lychee -v .

Please read the link checking action to determine if extra flags should be
provided.

Guides
------
.. _`Sphinx`: https://www.sphinx-doc.org
.. _`reStructuredText`: https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html
.. _`Read the Docs`: https://about.readthedocs.com
.. _`docs`: https://github.com/bandframework/OpenBT/tree/main/docs

The User Guides and the Developer Guide are all developed in a single Sphinx_
project within the docs_ folder, which facilitates publication |via| `Read the
Docs`_.  The guides' contents are presently assembled from files only in
``docs``, which are written in reStructuredText_.

Refer to the :ref:`developer_env` section to find more information about
rendering HTML- and PDF-format version of the documentation locally.

.. todo::
    Should the docstrings in the Python package be updated so that their
    contents generate low-level API docs for the Python User Guide?

Macro Definitions
-----------------
Common and |openbt|-specific LaTeX math mode macros are defined in

* `docs/latex_macros_base.json <https://github.com/bandframework/OpenBT/blob/main/docs/latex_macros_base.json>`_
* `docs/latex_macros_notation.json <https://github.com/bandframework/OpenBT/blob/main/docs/latex_macros_notation.json>`_

to aid in presenting clear, concise, uniform notation across all documents
related to this project.  Similarly, a set of text macros are defined in

* `docs/sphinx_macros.json <https://github.com/bandframework/OpenBT/blob/main/docs/sphinx_macros.json>`_

Please familiarize yourself with this list of macros before working on our
documents and please use the macros consistently throughout all documentation.
