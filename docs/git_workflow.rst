Git Workflow
============
Since we are currently standing this repository up, we are working with an
informal git workflow.  A minimal set of rules are

.. note::

   If merge conflicts exist that block the merging of the PR through the GitHub
   web interface, do **not** resolve the conflicts through the web interface,
   which might result in unwanted side effects.  Rather, a gatekeeper should
   resolve the conflicts in a local clone, merge locally, and push.

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
