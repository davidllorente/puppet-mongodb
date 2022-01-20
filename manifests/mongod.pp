# == definition mongodb::mongod
define mongodb::mongod (
  $mongod_instance                        = $name,
  $mongod_bind_ip                         = $::ipaddress,
  $mongod_port                            = 27017,
  $mongod_replSet                         = '',
  $mongod_enable                          = true,
  $mongod_restart_on_change               = false,
  $mongod_running                         = true,
  $mongod_configsvr                       = false,
  $mongod_shardsvr                        = false,
  $mongod_logappend                       = true,
  $mongod_rest                            = true,
  $mongod_fork                            = true,
  $mongod_useauth                         = false,
  $mongod_engine                          = 'wiredTiger',
  $mongod_monit                           = false,
  $mongod_operation_profiling_slowms      = '',
  $mongod_operation_profiling_mode        = '',
  $mongod_add_options                     = [],
  $mongod_deactivate_transparent_hugepage = false,
) {

  $db_specific_dir = "${::mongodb::params::dbdir}/mongod_${mongod_instance}"
  $osfamily_lc = downcase($::osfamily)

  if $mongod_restart_on_change {
    $notify = Service["mongod_${mongod_instance}"]
    $subscribe = Exec["Reload systemd daemon for new mongod_${mongod_instance} service config(s)"]
  } else {
    $notify = undef
    $subscribe = undef
  }

  file {
    "/etc/mongod.conf":
      ensure  => 'absent', #just to remove the default conf as created by the install process
  }

  file {
    "/etc/mongod_${mongod_instance}.conf":
      content => template('mongodb/mongod.conf.yaml.erb'),
      mode    => '0755',
      notify  => $notify,
      require => Class['mongodb::install'];
  }

  file {
    $db_specific_dir:
      ensure  => directory,
      owner   => $::mongodb::params::run_as_user,
      group   => $::mongodb::params::run_as_group,
      notify  => $notify,
      require => Class['mongodb::install'],
  }

  if $mongodb::params::systemd_os {
    $service_provider = 'systemd'
    file {
      "/etc/init.d/mongod_${mongod_instance}":
        ensure => absent,
    }

    file { "mongod_${mongod_instance}_service":
      path    => "/etc/systemd/system/mongod_${mongod_instance}.service",
      content => template('mongodb/systemd/mongod.service.erb'),
      mode    => '0644',
      require => [
        Class['mongodb::install'],
        File["/etc/init.d/mongod_${mongod_instance}"]
      ]
    }

    ## THP (Transparent Huge Pages) service for disabling it if desired (as recommended by mongo)
    file { "mongod_${mongod_instance}_thp_service":
      path    => "/etc/systemd/system/mongod_${mongod_instance}_thp.service",
      content => template('mongodb/systemd/mongod_thp.service.erb'),
      mode    => '0644',
      require => [
        Class['mongodb::install'],
        File["/etc/init.d/mongod_${mongod_instance}"]
      ]
    }

    exec { "Reload systemd daemon for new mongod_${mongod_instance} service config(s)":
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      subscribe   => [
        File["mongod_${mongod_instance}_service"],
        File["mongod_${mongod_instance}_thp_service"],
      ]
    }

    service { "mongod_${mongod_instance}_thp":
      ensure     => $mongod_running,
      enable     => $mongod_enable,
      hasstatus  => true,
      hasrestart => true,
      provider   => $service_provider,
      require    => [
        File[
          "/etc/mongod_${mongod_instance}.conf",
          "mongod_${mongod_instance}_thp_service",
          $db_specific_dir]],
      before     => Anchor['mongodb::end'],
      subscribe  => $subscribe,
    }


  } else {
    # Workaround for Ubuntu 14.04 and Debian 7
    if ( versioncmp($::operatingsystemmajrelease, '14.04') == 0 ) {
      $service_provider = undef # let puppet decide
    } elsif ( versioncmp($::operatingsystemmajrelease, '8') < 0 ) {
      $service_provider = undef # let puppet decide
    } else {
      $service_provider = 'init'
    }

    file { "mongod_${mongod_instance}_service":
        path    => "/etc/init.d/mongod_${mongod_instance}",
        content => template("mongodb/init.d/${osfamily_lc}_mongod.conf.erb"),
        mode    => '0755',
        require => Class['mongodb::install'],
    }
  }

  if ($mongod_monit != false) {
    # notify { "mongod_monit is : ${mongod_monit}": }
    class { 'mongodb::monit':
      instance_name => $mongod_instance,
      instance_port => $mongod_port,
      require       => Anchor['mongodb::install::end'],
      before        => Anchor['mongodb::end'],
    }
  }

  if ($mongod_useauth != false) {
    file { "/etc/mongod_${mongod_instance}.key":
      content => template('mongodb/mongod.key.erb'),
      mode    => '0700',
      owner   => $mongodb::params::run_as_user,
      require => Class['mongodb::install'],
      notify  => Service["mongod_${mongod_instance}"],
    }
  }

  service { "mongod_${mongod_instance}":
    ensure     => $mongod_running,
    enable     => $mongod_enable,
    hasstatus  => true,
    hasrestart => true,
    provider   => $service_provider,
    require    => [
      File[
        "/etc/mongod_${mongod_instance}.conf",
        "mongod_${mongod_instance}_service",
        $db_specific_dir]],
    before     => Anchor['mongodb::end'],
    subscribe  => $subscribe,
  }

}
