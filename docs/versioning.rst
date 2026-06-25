Versioning
==========
.. _C++ command line tools: https://github.com/bandframework/OpenBT/blob/main/meson.build

This repository contains severel different, but related software products.  To
reduce the complexity of managing software versions and to simplify the release
process, a single version identifier will be assigned to the entire repository
and its contents rather than designating, for example, a separate version
identifier to the `C++ command line tools`_, the Python package, and the R
package.

Therefore, for this scheme a release might include changes to only one component
of the repository (e.g., the Python package), but the associated change in the
version identifier would be applied to all components in the repository.  This
includes the unaltered R package, which has no direct relationship with the
Python package.

For the Python package, there would be no need to upload to PyPI a "new" version
of the package when the Python package was not altered as part of the changes.
While users can access and use such "repeat" versions of the package through a
local clone, the majority of users, who we assume will install directly from
PyPI with pip install, will not be exposed to them. They will potentially see,
however, skipped versions in the package's publication history on PyPI.
