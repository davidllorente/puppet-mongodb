# == Class: mongodb::install
#
#
class mongodb::install (
  $repo_manage          = true,
  $extra_package_name   = undef,
  $extra_package_ensure = 'installed'
) {

    anchor { 'mongodb::install::begin': }
    anchor { 'mongodb::install::end': }

    if ($repo_manage == true) {
        include $::mongodb::params::repo_class
        # On Debian, the package name may change when changing repos.
        case $::osfamily {
          'Debian': {
            $mongodb_package_name = $::mongodb::repos::apt::package_name
          }
          default: {
            $mongodb_package_name = $::mongodb::package_name
          }
        }
        $mongodb_repo_package_require = [
          Anchor['mongodb::install::begin'],
          Class[$::mongodb::params::repo_class]
        ]
    } else {
        $mongodb_package_name = $::mongodb::package_name
        $mongodb_repo_package_require = [
          Anchor['mongodb::install::begin']
        ]
    }

    $package_ensure = $::mongodb::package_ensure

    package { $mongodb_package_name:
      ensure  => $package_ensure,
      require => $mongodb_repo_package_require,
      before  => [Anchor['mongodb::install::end']]
    }

    if ($extra_package_name != undef) {
      package { $extra_package_name:
        ensure  => $extra_package_ensure,
        require => $mongodb_repo_package_require,
        before  => [Anchor['mongodb::install::end']]
      }
    }

}
