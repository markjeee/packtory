# Overview

This is packtory, an easy to use system packaging tool for your Ruby
gems. Build package for Debian, RPM, and Homebrew, directly
from your gem repo.

Support for building native extensions is available, using a post-install step of the target package.

# How to use

To install,

```
gem install packtory
packtory <root_path_to_gem>
```

By default, this will build a Debian package that is compatible to install in Ubuntu and Debian.

To specify the package output:

```
env PACKAGE_OUTPUT=rpm packtory
```

Additional options are available as follows:

```
; Specify a gemspec file to use
env GEM_SPECFILE="subpath_to/gemname.gemspec" packtory <root_path_to_gem>

; Specify a Gemfile to use, otherwise, packtory will auto-generate a clean one.
env BUNDLE_GEMFILE="$build/spec/gemfiles/Gemfile.19" packtory <root_path_to_gem>

; Specify the version of ruby system package
env PACKAGE_RUBY_VERSION="2.5.1" packtory <root_path_to_gem>

; Specify additional system dependencies of the generated package
env PACKAGE_DEPENDENCIES="mysql,mysql-dev,libxml++>=2.6" packtory <root_path_to_gem>
```

# Requirements

This gem depends on `fpm` to build the final system package. You may install it manually:

```
gem install fpm
```

And if building for RPM, you will need the package that contains the `rpmbuild` binary.

```
; In Debian/Ubuntu
apt install rpm

; In Fedora/CentOS
yum install rpm-build

; In Homebrew
brew install rpm
```

# Compatibility

If not specified, this buildpack will detect for a gemspec (\*.gemspec) file at the root
path of your repo, then use that to gather the files of your gem and gem dependencies. After which,
it vendorized all files to build the target package.

If a gem has native extensions, the extensions are not built at the time of building the
package, but rather, a post-install script is included, that builds them right after the
target package is installed in the system. If any native extensions requires other system
libraries, you may specify additional package dependencies to be installed prior to
installing the target package.

As of this version, this buildpack do not support packaging gems without a specific gemspec file.

# Limitations

Note, the build process will not load the code of your gem or the other dependencies.
Only the code in the gemspec is loaded using the ruby version of the build environment.
Please make sure the gemspec may be loaded properly, and additional code requirements
are compatible.

# Contribution and Improvements

Please fork the code, make the changes, and submit a pull request for us to review
your contributions.

## Feature requests

If you think it would be nice to have a particular feature that is presently not
implemented, we would love to hear that and consider working on it. Just open an
issue in Github.

# Questions

Please open a Github Issue if you have any other questions or problems.
