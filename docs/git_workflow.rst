Git Workflow
============

.. note::

   If merge conflicts exist that block the merging of the PR through the GitHub
   web interface, do **not** resolve the conflicts through the web interface,
   which might result in unwanted side effects.  Rather, a gatekeeper should
   resolve the conflicts in a local clone, merge locally, and push.

Since we are currently standing this repository up, we are working with an
informal git workflow.  A minimal set of rules are

#. No one should make direct commits to the ``main`` branch.
#. Each addition and change should be made on a dedicated feature branch that is
   based off of the latest commit on the ``main`` branch.  Try to group related
   changes together into a single branch so that you find a happy balance
   between a branch that is trivial in it's simplicity and a branch that is a
   beast.  Our goal is to have appropriately-sized branches that result in
   effective, clean reviews.
#. At any point in time, there should be one and only one owner of a feature
   branch, which means that only that person can commit to that branch and push
   commits to the main repository.  Ownership of the branch should be handed
   over to another developer by explicit communication only.
#. Do not create branches off of other feature branches.
#. If the contents of a feature branch are deemed as good and ready for
   inclusion in the software, the branch's developer should create a PR for
   merging the feature branch into ``main``.
#. If a PR is ready for review, the developer should first merge ``main`` into
   the feature branch if ``main`` has been updated since the feature branch was
   based off of it.  This forces the integration of the new work in ``main`` to
   occur in the feature branch rather than in ``main``, which we try to protect.
#. If a PR is ready for review and synchronized with ``main``, the branch
   developer should perform a self-review of the PR.  Once completed, the PR
   must undergo a review by a different developer that is also a gatekeeper of
   the repository.
#. Once the developer and the reviewers have converged on an acceptable set of
   changes, a gatekeeper will merge the branch into ``main`` and confirm that
   all actions pass on the associated merge commit.

Developers are encouraged to create PRs early during branch development to begin
and record a dialogue with potential reviewers in the PR.

GitHub Actions
--------------

All of the following actions run automatically on every push and pull request to
``main``.  A merge should only proceed once all actions pass.

Documentation
~~~~~~~~~~~~~

* **Check Spelling** — Checks all ``.rst`` and ``.md`` files in the repository
  for typographic errors using the ``typos`` tool with the ``typos.toml``
  configuration file.

* **Check Links** — Checks all ``.rst`` and ``.md`` files for broken URLs using
  the ``lychee`` tool.  In addition to running on push and pull request, this
  action runs on a weekly schedule to catch links that break between
  contributions.

* **Build Sphinx Docs** — Builds the |openbt| documentation in both HTML and
  PDF format using |tox|.  The built documents are uploaded as a downloadable
  artifact so that contributors can review rendered documentation without
  needing a local build environment.

Python Package Testing
~~~~~~~~~~~~~~~~~~~~~~

* **Test |openbt| Python Source Distribution** — The primary test action.  Builds
  a Python source distribution and tests it across a matrix of operating
  systems, MPI implementations, and Python versions to validate broad
  compatibility.  This action additionally runs on published releases so that
  the source distribution built and tested by the action, which is stored as an
  artifact, can be manually uploaded to PyPI as the official release
  distribution.

* **Test |openbt| Developer-mode Installation** — Tests the editable installation
  (``pip install -e .``) on a reduced matrix.  MPI is intentionally installed
  |via| |pip| rather than a system package manager to confirm that pip-installed
  MPI implementations work correctly.

* **Test |openbt| in Anaconda** — Tests installation inside a conda environment
  across a matrix of operating systems and installs |via| |pip| a prebuilt
  Open MPI installation included in a Python package.

* **Measure |openbt| Python Coverage** — Runs the full Python test suite with
  coverage measurement using |tox| and uploads the raw coverage file, XML
  report, and HTML report as artifacts.

C++ Tools Testing
~~~~~~~~~~~~~~~~~

* **Test |openbt| C++ Command Line Tools** — Builds and tests the C++ command
  line tools directly across a matrix of operating systems and MPI implementations, independently of the Python package.  Prints dynamic library
  linkage information for each built binary so that developers can verify the
  correct MPI implementation was linked.
