.. _versioning:

Versioning
==========
This repository contains several different, but related software products.  To
reduce the complexity of managing software versions and to simplify the release
process, a single version identifier will be assigned to the entire repository
and its contents rather than designating, for example, a separate version
identifier to the C++ command line tools, the Python package, and the R package.

Therefore, for this scheme a release might include changes to only one component
of the repository (|eg| the Python package), but the associated change in the
version identifier would be applied to all components in the repository.  This
would include the unaltered R package, which has no direct relationship with the
Python package.

For the Python package, there would be no need to upload to PyPI a "new" version
of the package when the Python package was not altered as part of the changes.
While users can access and use such "repeat" versions of the package through a
local clone, the majority of users, who we assume will install directly from
PyPI with ``pip install``, will not be exposed to them. They will potentially
see, however, skipped versions in the package's publication history on PyPI.

Versioning rules
----------------
.. _SemVer: https://semver.org

* Only commits on the ``main`` branch can be considered for release
* Version identifiers are strings that adhere to semantic versioning (SemVer_),
  and the version increment made will be made based on the most significant
  change or addition made across all software products in the repository
* Release commits will be tagged using ``vX.Y.Z`` in accordance with
  ``setuptools-scm`` requirements to allow for automatic versioning of the
  Python package
* Each release should be made publicly through the repository's release
  facilities as offered by GitHub

C++ command line tools
----------------------
.. _specification file: https://github.com/bandframework/OpenBT/blob/main/meson.build

The version of the C++ command line tools is specified in the tools' Meson build
system `specification file`_.  If a change is made in the tools or its build
system that requires a new version, it is a natural consequence that all derived
software products (|eg| the Python package) have their version number altered in
a consistent way.

Based on our versioning scheme, the tools' version will be updated even if a
change is made only in one or more of the derived software products.

Python package
--------------
We prefer to adhere to the standard versioning practices of the Python
community, which drives the versioning scheme of the whole repository. The
version of the Python package is managed automatically by the configuration of
``setuptools-scm`` in ``pyproject.toml``.  The version identifier for the source
distribution constructed from a tagged commit will automatically be set to the
tag's name.  Only these distributions should be distributed officially.
