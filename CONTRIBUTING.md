# Contributing to SlackGamebot

This project is work of [many contributors](https://github.com/dblock/slack-gamebot2/graphs/contributors).

You're encouraged to submit [pull requests](https://github.com/dblock/slack-gamebot2/pulls), [propose features and discuss issues](https://github.com/dblock/slack-gamebot2/issues).

See [DEV](DEV.md) for how to setup a development environment.

In the examples below, substitute your Github username for `contributor` in URLs.

## Fork the Project

Fork the [project on Githubo](https://github.com/dblock/slack-gamebot2) and check out your copy.

```
git clone https://github.com/contributor/slack-gamebot2.git
cd slack-gamebot2
git remote add upstream https://github.com/dblock/slack-gamebot2.git
```

## Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.

```
git checkout main
git pull upstream main
git checkout -b my-feature-branch
```

## Bundle Install and Test

Ensure that you can build the project and run tests. You will need these dependencies in order to run tests.
- [mongodb](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- ruby 2.3.1 (use rbenv)

```
bundle install
bundle exec rake
```

## Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build.
Add to [spec](spec).

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

## Write Code

Implement your feature or bug fix.

Ruby style is enforced with [Rubocop](https://github.com/bbatsov/rubocop).
Run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

## Write Documentation

Document any external behavior in the [README](README.md).

## Update Changelog

Add a line to [CHANGELOG](CHANGELOG.md) under *Next Release*.
Make it look like every other line, including your name and link to your Github account.

## Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.

```
git add ...
git commit
```

## Push

```
git push origin my-feature-branch
```

## Make a Pull Request

Go to https://github.com/contributor/slack-gamebot and select your feature branch.
Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

## Rebase

If you've been working on a change for a while, rebase with upstream/main.

```
git fetch upstream
git rebase upstream/main
git push origin my-feature-branch -f
```

## Update CHANGELOG Again

Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/dblock/slack-gamebot2/pull/123): Reticulated splines - [@contributor](https://github.com/contributor).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

## Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with Travis-CI. Everything should look green, otherwise fix issues and amend your commit as described above.

## Be Patient

It's likely that your change will not be merged and that the nitpicky maintainers will ask you to do more, or fix seemingly benign problems. Hang on there!

## Thank You

Please do know that we really appreciate and value your time and work. We love you, really.
