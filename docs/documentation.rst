Documentation
=============

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

Refer to the developer guide section on development |via| |tox| to find more
information about rendering HTML- and PDF-format version of the documentation
locally.

.. todo::
    Should the docstrings in the Python package be updated so that their
    contents generate low-level API docs for the Python User Guide?

Macro Definitions
-----------------
A set of text macros are defined in

* `docs/sphinx_macros.json <https://github.com/bandframework/OpenBT/blob/main/docs/sphinx_macros.json>`_

and common and |openbt|-specific LaTeX math mode macros are defined in

* `docs/latex_macros_base.json <https://github.com/bandframework/OpenBT/blob/main/docs/latex_macros_base.json>`_
* `docs/latex_macros_notation.json <https://github.com/bandframework/OpenBT/blob/main/docs/latex_macros_notation.json>`_

to aid in presenting clear, concise, uniform notation across all documents
related to this project.

Please familiarize yourself with this list of macros before working on our
documents and please use the macros consistently as your work.
