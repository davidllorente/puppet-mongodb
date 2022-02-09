# == Class: mongodb::repo::yum
#
# This class adds the official YUM repo of mongodb.org
#
# === Parameters:
#
# None.
#
class mongodb::repos::yum {

  yumrepo { 'mongodb_yum_repo':
    ensure   => present,
    name     => 'MongoDB_Repository',
    descr    => 'MongoDB Official Yum Repository',
    baseurl  => 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/5.0/x86_64/',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://www.mongodb.org/static/pgp/server-5.0.asc',
  }

}
