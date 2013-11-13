This module implements a package provider for the mac homebrew packaging system.

It assumes the brew command is installed in `/usr/local/bin/brew`

Example usage:

```
package { "rsync":
        ensure => installed,
        provider => homebrew
}

package { "git":
        ensure => latest,
        provider => homebrew
}

package { "vim":
        ensure => latest,
        provider => homebrew,
        install_options = ["--override-system-vi"]
}
```
