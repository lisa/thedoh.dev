---
title: Git Rebasing
parentcategory: "random-projects"
category: git
order: 10
---

# Git Rebasing

Consider a git log similar to the following which should be squashed
into one commit to eliminate intermediate commits:

    commit 17be8105fc9c87614aefda7ea395b97fc3887209 (HEAD -> port-to-go, origin/port-to-go)
    commit e64cee25a5697a6b5b35537eed2ef1b328b199cc
    commit 80567bd752b76990f777129580c4b9cfcbcebf81
    commit ec3c0503ef8da40ea9852306e8414ff52ebaeb9d
    commit 3f4d8edefdee6afc603b980fe7bfb125e10a22fd
    commit d582b40402f8935f4d2f1f5d59db5badd5170652
    commit b628992c8cddf7c8b03b8fd8618153bdb30b6370
    commit f676768b09906bf5cc6ab4a1e54c418ffb8cca9d
    commit 8f002ce0fe45e8836f15f06b4fa98b8eac1874ad
    commit daa554d45ac4e9a2485e514ff6866494e2a6ffb8
    commit a5b315aba35d993fd5d0ab523b9a4943173582fd
    commit ada71a9da7ee268b9199ddcf8af1130d05406961
    commit a1a36b6d58c8f5b5b7f7f02290beacd008174478 (upstream/master, origin/master, origin/HEAD, master)

Commit `a1a36b6` is the source branch (`master`) from which the
development branch (`port-to-go`) takes place. All of the commits
between `ada71a9..17be810` (inclusive) should be squashed into a single
commit so the intervening history is collapsed into a single commit. The
reason to do this is to prevent the merge commit (to merge `port-to-go`
into `master`) from pulling in all of these commits that reflect
incremental development in the feature (represented by the `port-to-go`
branch, but not necessarily for the product (represented by the `master`
branch).

To squash these, issue the command `git rebase -i
a1a36b6d58c8f5b5b7f7f02290beacd008174478` because the way git works is
to treat `a1a36b6` as a non-inclusive boundary. Vim will open and then
this will be in the screen (line numbers are copied from Vim's screen
rendering for clarity, and are not part of git).

``` 
  1 pick ada71a9 This PR introduces a ground-up rewrite of the Python framework in Go. The rewrite aims to be functionally identical to the original Python webhook (except the rewrite uses `admissionregistration.k8s.io/v1` instead of `v1beta1`), keeping pre-exis    ting webhooks at the same URI. The original home for this was my in my personal github [lisa/k8s-webhook-framework](https://github.com/lisa/k8s-webhook-framework) for development.
  2 pick a5b315a PR feedback
  3 pick daa554d Remove cert injector portion
  4 pick 8f002ce regular-user: should allow ^system: too
  5 pick f676768 Re-add certinjector, use daemonset on master nodes
  6 pick b628992 When updating, set OldObject too
  7 pick d582b40 Unify interface
  8 pick 3f4d8ed Delete unused code
  9 pick ec3c050 Log response encoding errors
 10 pick 80567bd Add user-validation webhook
 11 pick e64cee2 remove errant printf in the test
 12 pick 17be810 Updated SSS
 13
```

Every commit following line 1 should be <em>included</em> with that
first commit because that's really where the bulk of the work was taking
place. Everything following was an addition to the overall feature.

Following the list of commits is this reminder text from git:

``` 
 14 # Rebase a1a36b6..17be810 onto 17be810 (12 commands)
 15 #
 16 # Commands:
 17 # p, pick <commit> = use commit
 18 # r, reword <commit> = use commit, but edit the commit message
 19 # e, edit <commit> = use commit, but stop for amending
 20 # s, squash <commit> = use commit, but meld into previous commit
 21 # f, fixup <commit> = like "squash", but discard this commit's log message
 22 # x, exec <command> = run command (the rest of the line) using shell
 23 # b, break = stop here (continue rebase later with 'git rebase --continue')
 24 # d, drop <commit> = remove commit
 25 # l, label <label> = label current HEAD with a name
 26 # t, reset <label> = reset HEAD to a label
 27 # m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
 28 # .       create a merge commit using the original merge commit's
 29 # .       message (or the oneline, if no original merge commit was
 30 # .       specified). Use -c <commit> to reword the commit message.
 31 #
 32 # These lines can be re-ordered; they are executed from top to bottom.
 33 #
 34 # If you remove a line here THAT COMMIT WILL BE LOST.
 35 #
 36 # However, if you remove everything, the rebase will be aborted.
 37 #
```

Thus, we will "pick" that first commit, and for every following line,
"squash" it. Thus vim should read:

``` 
  1 pick ada71a9 This PR introduces a ground-up rewrite of the Python framework in Go. The rewrite aims to be functionally identical to the original Python webhook (except the rewrite uses `admissionregistration.k8s.io/v1` instead of `v1beta1`), keeping pre-exis    ting webhooks at the same URI. The original home for this was my in my personal github [lisa/k8s-webhook-framework](https://github.com/lisa/k8s-webhook-framework) for development.
  2 squash a5b315a PR feedback
  3 squash daa554d Remove cert injector portion
  4 squash 8f002ce regular-user: should allow ^system: too
  5 squash f676768 Re-add certinjector, use daemonset on master nodes
  6 squash b628992 When updating, set OldObject too
  7 squash d582b40 Unify interface
  8 squash 3f4d8ed Delete unused code
  9 squash ec3c050 Log response encoding errors
 10 squash 80567bd Add user-validation webhook
 11 squash e64cee2 remove errant printf in the test
 12 squash 17be810 Updated SSS
 13
```

In this example, git will mush them all together and return right to a
commit message window containing every commit message:

    # This is a combination of 12 commits.
    # This is the 1st commit message:
    
    This PR introduces a ground-up rewrite of the Python framework in Go.
    The rewrite aims to be functionally identical to the original Python
    webhook (except the rewrite uses `admissionregistration.k8s.io/v1`
    instead of `v1beta1`), keeping pre-existing webhooks at the same URI.
    The original home for this was my in my personal github
    [lisa/k8s-webhook-framework](https://github.com/lisa/k8s-webhook-framework)
    for development.
    
    There are several major changes:
    
    1. There are no longer YAML template files.  2. The YAML SelectorSyncSet
    is created with Go (see `build/syncset.go`).  3. All webhooks must be
    implemented in Go, and satisfy a specific interface (see
    `pkg/webhooks/register.go` and new `README.md`).  4. App-SRE PR check
    and build files have been altered.  5. The init container is rewritten
    in Go and included in the container image (as
    `/usr/local/bin/injector`).  6. The rewrite uses
    `admissionregistration.k8s.io/v1` instead of `v1beta1`.  7. There is no
    ability to make changes to the configuration by environment variables;
    they are in source code (see [Method](#method)).
    
    (For Red Hatters, refer to May 27, 2020 SREP Sprint 184 demo for
    additional information)
    
    The motivation for the rewrite centres around scaling and handling
    growing pains. When the Python framework was first created, the scope of
    it was quite small, handling only a single hook (Namespace validation),
    focused around SREP and intended to be a stopgap measure until other
    alternatives could be put into place.
    
    Since the inception of the Python framework we have seen the scope grow
    (and even shrink), and other teams contributing meaningful hooks.
    
    Moving to Go increases our ability to add more webhooks in a consistent
    way (refer to the interface in `pkg/webhooks/register.go` and
    `build/syncset.go`) while leaning into our Go expertise for its inherent
    type safety.
    
    The method behind the rewrite centred around the creation of a single,
    common interface to ensure a each webhook were as uniform in
    implementation as possible. The benefit is two-fold. First, when
    creating the webserver (`cmd/main.go`), each webhook is uniformly
    handled. Second, to create the SelectorSyncSet template, the same
    interface is used to iterate through all registered webhooks to
    programatically create the SelectorSyncSet template, removing the need
    for the previous `/templates` directory. Once the templates directory is
    removed the tedium of ensuring the correct content is copied/pasted in
    the right place, with the right name is eliminated, along with one more
    chance for error.
    
    The Go framework follow the "factory" and "registration" pattern where
    each webhook adds a file in `pkg/webhooks` to "register" itself using
    the `Register` function (`pkg/webhooks/register.go`), which in requires
    a webhook name and factory function as parameters. These inputs are
    stored in a `Webhooks` map (`[string)]WebhookFactory{}`) that consumers
    (such as `cmd/main.go` and `build/syncset.go`) may use to access each
    registered webhook.
    
    Environment variable configuration has been removed in favour of source
    code changes (or perhaps a [configuration
    file](https://github.com/lisa/k8s-webhook-framework/issues/32)). The
    reasoning behind removing environment variables is that changes to
    environment variables require changes to the SelectorSyncSet, which
    force a new build, so there is just as much work required to make a
    source code change. Additionally, relying on source code change means
    those changes can be run through the unit test framework to give a level
    of comfort for the changes.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #2:
    
    PR feedback
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #3:
    
    Remove cert injector portion
    
    openshift/service-ca-operator handles this now with the
    `service.beta.openshift.io/inject-cabundle=true'` annotation on the
    `ValidatingWebhookConfiguration` objects.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #4:
    
    regular-user: should allow ^system: too
    
    This was omitted by error.
    
    # This is the commit message #5:
    
    Re-add certinjector, use daemonset on master nodes
    
    The feature from openshift/service-ca-operator which supports
    auto-injecting a CA bundle into ValidatingWebhookConfiguration objects
    is a 4.4 feature. Currently the product is using 4.3, and so we still
    need this injection feature. Once 4.4 comes, the injector can be removed
    again. As a consequence, the webhook pods (see below) will again be
    created _after_ the ValidatingWebhookConfigurations, as with the
    original Python implementation.
    
    Additionally, the pods are now a DaemonSet, scheduled on nodes with the
    `node-role.kubernetes.io/master=` label.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #6:
    
    When updating, set OldObject too
    
    Technically the OldObject should be different than the Object (since
    there's an update), but for now no webhooks are comparing any changes.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #7:
    
    Unify interface
    
    In some places there were a pointer return and some places not and for
    no good reason. This has been unified across the board to not return a
    pointer. Additionally, method comments have been unified to reflect that
    they are implementing an interface.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #8:
    
    Delete unused code
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #9:
    
    Log response encoding errors
    
    Still would like to make these not use a recursive call
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #10:
    
    Add user-validation webhook
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #11:
    
    remove errant printf in the test
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # This is the commit message #12:
    
    Updated SSS
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>
    
    # Please enter the commit message for your changes. Lines starting
    # with '#' will be ignored, and an empty message aborts the commit.
    #
    # Date:      Sat May 30 17:29:36 2020 -0400
    #
    # interactive rebase in progress; onto a1a36b6
    # Last commands done (12 commands done):
    #    squash e64cee2 remove errant printf in the test
    #    squash 17be810 Updated SSS
    # No commands remaining.
    # You are currently rebasing branch 'port-to-go' on 'a1a36b6'.
    #
    # Changes to be committed:
    #   modified:   .gitignore
    #   modified:   Makefile
    #   modified:   README.md
    #   deleted:    build/00-osd-managed-cluster-validating-webhooks.selectorsyncset.yaml.tmpl
    #   modified:   build/Dockerfile
    #   deleted:    build/Dockerfile.test
    #   new file:   build/bin/entrypoint
    #   new file:   build/bin/user_setup
    #   modified:   build/build_deploy.sh
    #   deleted:    build/generate_syncset.py
    #   modified:   build/pr_check.sh
    #   modified:   build/selectorsyncset.yaml
    #   new file:   build/syncset.go
    #   new file:   cmd/injector/main.go
    #   new file:   cmd/main.go
    #   deleted:    deploy/01-webhook.namespace.yaml
    #   deleted:    deploy/02-webhook-cacert.configmap.yaml
    #   deleted:    deploy/02-webhook.permissions.yaml
    #   new file:   go.mod
    #   new file:   go.sum
    #   modified:   hack/test.sh
    #   new file:   pkg/certinjector/inject.go
    #   new file:   pkg/certinjector/inject_test.go
    #   new file:   pkg/helpers/response.go
    #   new file:   pkg/helpers/response_test.go
    #   new file:   pkg/testutils/testutils.go
    #   new file:   pkg/webhooks/add_group_hook.go
    #   new file:   pkg/webhooks/add_identity.go
    #   new file:   pkg/webhooks/add_namespace_hook.go
    #   new file:   pkg/webhooks/add_regularuser.go
    #   new file:   pkg/webhooks/add_user.go
    #   new file:   pkg/webhooks/group/group.go
    #   new file:   pkg/webhooks/group/group_test.go
    #   new file:   pkg/webhooks/identity/identity.go
    #   new file:   pkg/webhooks/identity/identity_test.go
    #   new file:   pkg/webhooks/namespace/namespace.go
    #   new file:   pkg/webhooks/namespace/namespace_test.go
    #   new file:   pkg/webhooks/register.go
    #   new file:   pkg/webhooks/regularuser/regularuser.go
    #   new file:   pkg/webhooks/regularuser/regularuser_test.go
    #   new file:   pkg/webhooks/user/user.go
    #   new file:   pkg/webhooks/user/user_test.go
    #   new file:   pkg/webhooks/utils/utils.go
    #   deleted:    src/README.md
    #   deleted:    src/gunicorn.py
    #   deleted:    src/init.py
    #   deleted:    src/requirements.txt
    #   deleted:    src/test-requirements.txt
    #   deleted:    src/webhook/__init__.py
    #   deleted:    src/webhook/group_validation.py
    #   deleted:    src/webhook/identity_validation.py
    #   deleted:    src/webhook/metrics.py
    #   deleted:    src/webhook/namespace_validation.py
    #   deleted:    src/webhook/regular_user_validation.py
    #   deleted:    src/webhook/request_helper/__init__.py
    #   deleted:    src/webhook/request_helper/responses.py
    #   deleted:    src/webhook/request_helper/validate.py
    #   deleted:    src/webhook/test_group_validation.py
    #   deleted:    src/webhook/test_identity_validation.py
    #   deleted:    src/webhook/test_namespace_validation.py
    #   deleted:    src/webhook/test_regular_user_validation.py
    #   deleted:    src/webhook/test_user_validation.py
    #   deleted:    src/webhook/user_validation.py
    #   deleted:    templates/01-webhook.namespace.yaml.tmpl
    #   deleted:    templates/02-prometheus-role-binding.yaml.tmpl
    #   deleted:    templates/02-prometheus_role.yaml.tmpl
    #   deleted:    templates/02-webhook-cacert.configmap.yaml.tmpl
    #   deleted:    templates/02-webhook.permissions.yaml.tmpl
    #   deleted:    templates/05-validation-webhook.service.yaml.tmpl
    #   deleted:    templates/10-group-validation.ValidatingWebhookConfiguration.yaml.tmpl
    #   deleted:    templates/10-identity-validation.ValidatingWebhookConfiguration.yaml.tmpl
    #   deleted:    templates/10-namespace-validation.ValidatingWebhookConfiguration.yaml.tmpl
    #   deleted:    templates/10-regular-user-validation.ValidatingWebhookConfiguration.yaml.tmpl
    #   deleted:    templates/10-user-validation.ValidatingWebhookConfiguration.yaml.tmpl
    #   deleted:    templates/20-validation-webhook.deployment.yaml.tmpl
    #   deleted:    templates/30-validation-webhook.servicemonitor.yaml.tmpl
    #
    # Untracked files:
    #   hack/extract-deployables.sh
    #

For this example, only the first commit message is relevant, and so the
commit message can remain

    This PR introduces a ground-up rewrite of the Python framework in Go.
    The rewrite aims to be functionally identical to the original Python
    webhook (except the rewrite uses `admissionregistration.k8s.io/v1`
    instead of `v1beta1`), keeping pre-existing webhooks at the same URI.
    The original home for this was my in my personal github
    [lisa/k8s-webhook-framework](https://github.com/lisa/k8s-webhook-framework)
    for development.
    
    There are several major changes:
    
    1. There are no longer YAML template files.  2. The YAML SelectorSyncSet
    is created with Go (see `build/syncset.go`).  3. All webhooks must be
    implemented in Go, and satisfy a specific interface (see
    `pkg/webhooks/register.go` and new `README.md`).  4. App-SRE PR check
    and build files have been altered.  5. The init container is rewritten
    in Go and included in the container image (as
    `/usr/local/bin/injector`).  6. The rewrite uses
    `admissionregistration.k8s.io/v1` instead of `v1beta1`.  7. There is no
    ability to make changes to the configuration by environment variables;
    they are in source code (see [Method](#method)).
    
    (For Red Hatters, refer to May 27, 2020 SREP Sprint 184 demo for
    additional information)
    
    The motivation for the rewrite centres around scaling and handling
    growing pains. When the Python framework was first created, the scope of
    it was quite small, handling only a single hook (Namespace validation),
    focused around SREP and intended to be a stopgap measure until other
    alternatives could be put into place.
    
    Since the inception of the Python framework we have seen the scope grow
    (and even shrink), and other teams contributing meaningful hooks.
    
    Moving to Go increases our ability to add more webhooks in a consistent
    way (refer to the interface in `pkg/webhooks/register.go` and
    `build/syncset.go`) while leaning into our Go expertise for its inherent
    type safety.
    
    The method behind the rewrite centred around the creation of a single,
    common interface to ensure a each webhook were as uniform in
    implementation as possible. The benefit is two-fold. First, when
    creating the webserver (`cmd/main.go`), each webhook is uniformly
    handled. Second, to create the SelectorSyncSet template, the same
    interface is used to iterate through all registered webhooks to
    programatically create the SelectorSyncSet template, removing the need
    for the previous `/templates` directory. Once the templates directory is
    removed the tedium of ensuring the correct content is copied/pasted in
    the right place, with the right name is eliminated, along with one more
    chance for error.
    
    The Go framework follow the "factory" and "registration" pattern where
    each webhook adds a file in `pkg/webhooks` to "register" itself using
    the `Register` function (`pkg/webhooks/register.go`), which in requires
    a webhook name and factory function as parameters. These inputs are
    stored in a `Webhooks` map (`[string)]WebhookFactory{}`) that consumers
    (such as `cmd/main.go` and `build/syncset.go`) may use to access each
    registered webhook.
    
    Environment variable configuration has been removed in favour of source
    code changes (or perhaps a [configuration
    file](https://github.com/lisa/k8s-webhook-framework/issues/32)). The
    reasoning behind removing environment variables is that changes to
    environment variables require changes to the SelectorSyncSet, which
    force a new build, so there is just as much work required to make a
    source code change. Additionally, relying on source code change means
    those changes can be run through the unit test framework to give a level
    of comfort for the changes.
    
    Signed-off-by: Lisa Seelye <lisa@users.noreply.github.com>

Save and exit the commit message input as normal:

    [detached HEAD f971357] Port Python webhook framework to Go
     Date: Sat May 30 17:29:36 2020 -0400
     76 files changed, 6274 insertions(+), 2354 deletions(-)
     rewrite Makefile (81%)
     rewrite README.md (98%)
     delete mode 100644 build/00-osd-managed-cluster-validating-webhooks.selectorsyncset.yaml.tmpl
     rewrite build/Dockerfile (98%)
     delete mode 100644 build/Dockerfile.test
     create mode 100755 build/bin/entrypoint
     create mode 100755 build/bin/user_setup
     delete mode 100644 build/generate_syncset.py
     create mode 100644 build/syncset.go
     create mode 100644 cmd/injector/main.go
     create mode 100644 cmd/main.go
     delete mode 100644 deploy/01-webhook.namespace.yaml
     delete mode 100644 deploy/02-webhook-cacert.configmap.yaml
     delete mode 100644 deploy/02-webhook.permissions.yaml
     create mode 100644 go.mod
     create mode 100644 go.sum
     rewrite hack/test.sh (97%)
     create mode 100644 pkg/certinjector/inject.go
     create mode 100644 pkg/certinjector/inject_test.go
     create mode 100644 pkg/helpers/response.go
     create mode 100644 pkg/helpers/response_test.go
     create mode 100644 pkg/testutils/testutils.go
     create mode 100644 pkg/webhooks/add_group_hook.go
     create mode 100644 pkg/webhooks/add_identity.go
     create mode 100644 pkg/webhooks/add_namespace_hook.go
     create mode 100644 pkg/webhooks/add_regularuser.go
     create mode 100644 pkg/webhooks/add_user.go
     create mode 100644 pkg/webhooks/group/group.go
     create mode 100644 pkg/webhooks/group/group_test.go
     create mode 100644 pkg/webhooks/identity/identity.go
     create mode 100644 pkg/webhooks/identity/identity_test.go
     create mode 100644 pkg/webhooks/namespace/namespace.go
     create mode 100644 pkg/webhooks/namespace/namespace_test.go
     create mode 100644 pkg/webhooks/register.go
     create mode 100644 pkg/webhooks/regularuser/regularuser.go
     create mode 100644 pkg/webhooks/regularuser/regularuser_test.go
     create mode 100644 pkg/webhooks/user/user.go
     create mode 100644 pkg/webhooks/user/user_test.go
     create mode 100644 pkg/webhooks/utils/utils.go
     delete mode 100644 src/README.md
     delete mode 100644 src/gunicorn.py
     delete mode 100644 src/init.py
     delete mode 100644 src/requirements.txt
     delete mode 100644 src/test-requirements.txt
     delete mode 100644 src/webhook/__init__.py
     delete mode 100644 src/webhook/group_validation.py
     delete mode 100644 src/webhook/identity_validation.py
     delete mode 100755 src/webhook/metrics.py
     delete mode 100644 src/webhook/namespace_validation.py
     delete mode 100644 src/webhook/regular_user_validation.py
     delete mode 100644 src/webhook/request_helper/__init__.py
     delete mode 100644 src/webhook/request_helper/responses.py
     delete mode 100644 src/webhook/request_helper/validate.py
     delete mode 100644 src/webhook/test_group_validation.py
     delete mode 100644 src/webhook/test_identity_validation.py
     delete mode 100644 src/webhook/test_namespace_validation.py
     delete mode 100644 src/webhook/test_regular_user_validation.py
     delete mode 100644 src/webhook/test_user_validation.py
     delete mode 100644 src/webhook/user_validation.py
     delete mode 100644 templates/01-webhook.namespace.yaml.tmpl
     delete mode 100644 templates/02-prometheus-role-binding.yaml.tmpl
     delete mode 100644 templates/02-prometheus_role.yaml.tmpl
     delete mode 100644 templates/02-webhook-cacert.configmap.yaml.tmpl
     delete mode 100644 templates/02-webhook.permissions.yaml.tmpl
     delete mode 100644 templates/05-validation-webhook.service.yaml.tmpl
     delete mode 100644 templates/10-group-validation.ValidatingWebhookConfiguration.yaml.tmpl
     delete mode 100644 templates/10-identity-validation.ValidatingWebhookConfiguration.yaml.tmpl
     delete mode 100644 templates/10-namespace-validation.ValidatingWebhookConfiguration.yaml.tmpl
     delete mode 100644 templates/10-regular-user-validation.ValidatingWebhookConfiguration.yaml.tmpl
     delete mode 100644 templates/10-user-validation.ValidatingWebhookConfiguration.yaml.tmpl
     delete mode 100644 templates/20-validation-webhook.deployment.yaml.tmpl
     delete mode 100644 templates/30-validation-webhook.servicemonitor.yaml.tmpl
    Successfully rebased and updated refs/heads/port-to-go.

Now push them to the upstream branch:

    lseelye@rhodium managed-cluster-validating-webhooks $ git push origin port-to-go
    To github.com:lisa/managed-cluster-validating-webhooks.git
     ! [rejected]        port-to-go -> port-to-go (non-fast-forward)
    error: failed to push some refs to 'github.com:lisa/managed-cluster-validating-webhooks.git'
    hint: Updates were rejected because the tip of your current branch is behind
    hint: its remote counterpart. Integrate the remote changes (e.g.
    hint: 'git pull ...') before pushing again.
    hint: See the 'Note about fast-forwards' in 'git push --help' for details.

Git will not allow it because the local branch does not match the remote
one. Compare the new `git log` with what was before.

    commit f971357f53e1993834ee90036c7a2f73633b8ebd (HEAD -> port-to-go, origin/port-to-go)
    commit a1a36b6d58c8f5b5b7f7f02290beacd008174478 (upstream/master, origin/master, origin/HEAD, master)

Git refuses to overwrite the previous history (what if another developer
had been doing work?) with the above. Thus, force push:

    lseelye@rhodium managed-cluster-validating-webhooks $ git push --force origin port-to-go
    Enumerating objects: 66, done.
    Counting objects: 100% (66/66), done.
    Delta compression using up to 12 threads
    Compressing objects: 100% (49/49), done.
    Writing objects: 100% (55/55), 124.83 KiB | 12.48 MiB/s, done.
    Total 55 (delta 10), reused 15 (delta 2), pack-reused 0
    remote: Resolving deltas: 100% (10/10), completed with 1 local object.
    To github.com:lisa/managed-cluster-validating-webhooks.git
     + 17be810...f971357 port-to-go -> port-to-go (forced update)

The branch is said to have been rebased, or squashed.
