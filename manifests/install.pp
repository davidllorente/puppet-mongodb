# == Class: mongodb::install
#
#
class mongodb::install (
  $repo_manage    = true,
  $package_version = undef
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

    if ($package_version == undef ) {
      $package_ensure = $::mongodb::package_ensure
    } else {
      $package_ensure = $package_version
    }

    package { 'mongodb-package':
      ensure  => $package_ensure,
      name    => $mongodb_package_name,
      require => $mongodb_repo_package_require,
      before  => [Anchor['mongodb::install::end']]
    }

}
