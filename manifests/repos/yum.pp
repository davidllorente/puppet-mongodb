# == Class: mongodb::repo::yum
#
# This class adds the official YUM repo of mongodb.org
#
# === Parameters:
#
# None.
#
class mongodb::repos::yum (
  $package_ensure = $::mongodb::package_ensure,
) {

  if (($package_ensure =~ /(\d+\.*)+\d/) and (versioncmp($package_ensure, '3.0.0') >= 0)) {
    $mongovernumbers = split($package_ensure, '[.]')
    $mongomajorminor = "${$mongovernumbers[0]}.${$mongovernumbers[1]}"
  } else { # if package_ensure does not specify version, assume 5.0
    $mongomajorminor = "5.0"
  }

  yumrepo { 'mongodb_yum_repo':
    ensure   => present,
    name     => "MongoDB_$mongomajorminor",
    descr    => "MongoDB $mongomajorminor Official Yum Repository",
    baseurl  => "https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/$mongomajorminor/x86_64/",
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => "https://www.mongodb.org/static/pgp/server-$mongomajorminor.asc",
  }

  yumrepo { 'old_mongodb_yum_repo':
    ensure   => absent,
    name     => "MongoDB_Repository",
  }

}
