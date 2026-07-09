Release Procedure
=================

Pre-release actions
-------------------
.. _Python version support: https://devguide.python.org/versions
.. _Numpy version support: https://numpy.org/neps/nep-0029-deprecation_policy.html#support-table
.. _Scipy version support: https://docs.scipy.org/doc/scipy/dev/core-dev/index.html#building-binary-installers
.. _scientific Python support: https://scientific-python.org/specs/spec-0000
.. _Supported action runner images: https://github.com/actions/runner-images
.. _specification file: https://github.com/bandframework/OpenBT/blob/main/meson.build
.. _DESCRIPTION file: https://github.com/bandframework/OpenBT/blob/main/Ropenbt/DESCRIPTION 

Seed the release process

* Determine the new version identifier ``vX.Y.Z`` needed for the release in
  accordance with the contents of :numref:`versioning`.
* Create a new release "super" issue (|ie| a GitHub issue that simply contains
  a list of links to other GitHub issues).

  * Content could be seeded from previous release's issue
  * All gatekeepers should converge on set of high-level tasks/goals for release
  * Create an issue for each approved task and add link to issue in the
    release "super" issue
  * As work proceeds, a link to each PR can be placed next to its associated
    issue's link

* Optionally, create a post-release issue to group together all new issues
  created during this prerelease/release work that won't be dealt with during
  the release, but that should be dealt with shortly after the release to
  maintain inertia and capitalize on the recent work/experience.

  * This should be maintained up-to-date.  Tasks that ultimately can be put off
    until later can be moved out of this issue.  Issues that will no longer be
    dealt with as part of the review can be transferred from the release to
    post-release issue.

* Notify BAND framework team that a new version will be released to determine
  what steps will need to be made, if any, within the framework once the release
  is finalized.

Once all tasks have been executed

* Check if a new version of the Eigen package is available through the Meson
  build system's wrapdb facility and assess if the new version should be adopted
  and tested.
* Review and update all metadata in ``setup.py``
* Review all external dependencies and their stated versions to see if they need
  updating and address on a feature branch

  * `Python version support`_
  * `Numpy version support`_
  * `Scipy version support`_
  * `scientific Python support`_
  * Confirm that all version information specified in ``setup.py``,
    ``pyproject.toml``, and ``tox.ini`` are consistent

* Modernize all repository actions in accord with changes to supported versions
  and updated GH action infrastructure

  * `Supported action runner images`_
  * Are there test setups that are presently excluded and that should be added
    back in?

* Review README including badges for necessary cleaning/updates

  * New references?
  * Update citation?
  * Check links

* Review all documentation associated with the repository including examples to
  determine if any updates still need to be made and address on a feature branch

  * Sphinx/RTD User and Developer Guides

* Confirm continued adherence to all binding requirements (|eg| BAND SDK)
* Set the version of the C++ command line tools in their Meson build system
  `specification file`_ to the correct version identifier determined earlier
* Set the version of the R package in its `DESCRIPTION file`_ to the correct
  version identifier determined earlier.  Set release date as well.

Release actions
---------------
When a particular commit on ``main`` is to be deemed a release,

#. Confirm that all actions ran successfully on the proposed commit
#. Perform any review of the action logs deemed necessary based on the changes
   included in the release
#. Perform any review of the artifacts created by the actions deemed necessary
   based on the changes included in the release
#. Tag the release commit with the name ``vX.Y.Z`` and push.  This will trigger
   the ``test_py_sdist`` GitHub action, which builds the source distribution
   with the correct version identifier and tests it.
#. Confirm that the action passed with no errors or warnings.  Review the
   action's log.
#. Create a **draft** release with the correct tag ``vX.Y.Z`` and indicate if
   the release included changes to the C++ command line tools, the Python
   package, the R package, or some combination of these.
#. Carry out all necessary checks for the different software products (see
   below).
#. Change the state of the release to **publish**.

Command line tools
^^^^^^^^^^^^^^^^^^
#. Gatekeepers to follow installation guide to install and test the command line
   tools.  This should include a review of the build logs and confirming correct
   logging of the new release version identifier.

Python package
^^^^^^^^^^^^^^
.. _twine instructions: https://twine.readthedocs.io/en/stable/index.html#using-twine

.. note::
    Since PyPI does not permit the uploading of a revised version to overwrite a
    previous upload of that same version, these steps should likely be done only
    **after** having carried out the sanity checks for all other software
    products.

If the changes in the release do **not** include changes to the C++ command line
tools or the Python package, then no actions are needed.  In particular, we do
**not** upload to PyPI the source distributions created with this new versioned
release.

Otherwise,

#. Download the source distribution artifact from the ``test_py_sdist`` action
   and confirm that filename contains the desired version identifier.
#. Decompress the source distribution with ``tar xvfz`` and confirm correct,
   minimal contents including the presence of the LICENSE file.

   * One side effect of the use of ``setuptools-scm`` is that by default it
     includes in the distribution all files located within ``openbt_pypkg``.
     However, many files and folders in that space do **not** need to be
     distributed (|eg| Flake8 configuration files and |openbt| command line
     tools installed during development in ``src/openbt/bin``).  This is what
     "minimal" means above.  Files and folders that should not be included in
     the distribution are specified in ``MANIFEST.in``.
   * Review the metadata to ensure correct and complete.  This should include
     the correct specification of the new version identifier.

#. Gatekeepers to follow installation guide to install and test the Python
   package in clean virtual environments |via| all provided mechanisms (aside
   from ``pip install``) as well as by installing from the release's source
   distribution.
#. Create a clean virtual environment, update |pip|, and install ``twine``.
#. Use that venv to publish the downloaded source distribution to PyPI following
   the `twine instructions`_.  Note that to upload the distribution, you will
   need to know either your username and password or have an API token that you
   can generate on the PyPI website under your personal settings.
#. Review the package's webpage on PyPI.
#. In a clean virtual environment, follow the installation guide for installing
   from |pip| and to test the installation

R package
^^^^^^^^^
#. Gatekeepers to follow installation guide to install and test the R
   package in a clean environment

Post-release actions
--------------------
* Carry out all necessary tasks to integrate the release within the BAND
  framework.
* Update this document based on lessons learned.
* Review all open issues and pull requests.  Comment and close where possible.
  Clean-up the post-release issue in preparation for carrying out the work that
  it requests.
