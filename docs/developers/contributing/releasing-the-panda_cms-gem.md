---
title: Releasing the panda-cms gem
layout: default
parent: Contributing
---

## Releasing

The **panda-cms** gem uses semantic versioning.

### Installing `gem-release`

Installing [gem-release](https://github.com/svenfuchs/gem-release) makes some parts of the release cycle easier:

```
gem install gem-release
```

### Releasing a new version of the `panda-cms` gem

With no staged changes, to set the next version number, run:

```
RELEASE_VERSION=$(gem bump --pretend --no-commit | awk '{ print $4 }' | tr -d '[:space:]')
echo $RELEASE_VERSION
```

This should output the next patch release version.

You can also set `RELEASE_VERSION` manually:

```
RELEASE_VERSION=0.6.2
```

To release the gem **to this version number**, run:

```
git checkout -b release/v$RELEASE_VERSION
gem bump --no-commit --version $RELEASE_VERSION
bundle update
git commit -am "Release $RELEASE_VERSION"
git tag -a $RELEASE_VERSION -m "Release $RELEASE_VERSION"
git push origin release/v$RELEASE_VERSION
gem release panda-cms -v $RELEASE_VERSION -g
git checkout main && git merge release/v$RELEASE_VERSION
git push origin main
git push origin :release/v$RELEASE_VERSION
```

To release the gem to another version, set `RELEASE_VERSION` yourself first.
