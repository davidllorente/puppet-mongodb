# == definition mongodb::mongos
define mongodb::mongos (
  $mongos_configServers,
  $mongos_instance          = $name,
  $mongos_bind_ip           = "localhost,127.0.0.1",
  $mongos_port              = 27017,
  $mongos_service_manage    = true,
  $mongos_enable            = true,
  $mongos_restart_on_change = false,
  $mongos_running           = true,
  $mongos_logappend         = true,
  $mongos_fork              = true,
  $mongos_useauth           = false,
  $mongos_engine            = 'wiredTiger',
  $mongos_add_options       = [],
  $mongos_start_detector    = true
) {

  $db_specific_dir = "${::mongodb::dbdir}/mongos_${mongos_instance}"
  $osfamily_lc = downcase($::osfamily)

  if $mongos_restart_on_change {
    $notify = Service["mongos_${mongos_instance}"]
    $subscribe = Exec["Reload systemd daemon for new mongos_${mongos_instance} service config"]
  } else {
    $notify = undef
    $subscribe = undef
  }

  file {
    "/etc/mongos_${mongos_instance}.conf":
      content => template('mongodb/mongos.conf.yaml.erb'),
      mode    => '0755',
      notify  => $notify,
      require => Class['mongodb::install'],
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
      "/etc/init.d/mongos_${mongos_instance}":
        ensure => absent,
    }

    file { "mongos_${mongos_instance}_service":
      path    => "/lib/systemd/system/mongos_${mongos_instance}.service",
      content => template('mongodb/systemd/mongos.service.erb'),
      mode    => '0644',
      require => [
        Class['mongodb::install'],
        File["/etc/init.d/mongos_${mongos_instance}"]
      ]
    }

    exec { "Reload systemd daemon for new mongos_${mongos_instance} service config":
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      subscribe   => [
        File["mongos_${mongos_instance}_service"],
      ]
    }

  } else {
    # Workaround for Ubuntu 14.04
    if ( versioncmp($::operatingsystemmajrelease, '14.04') == 0 ) {
      $service_provider = undef # let puppet decide
    } else {
      $service_provider = 'init'
    }

    file { "mongos_${mongos_instance}_service":
        path    => "/etc/init.d/mongos_${mongos_instance}",
        content => template("mongodb/init.d/${osfamily_lc}_mongos.conf.erb"),
        mode    => '0755',
        require => Class['mongodb::install'],
    }
  }

  # wait for servers starting
  if $mongos_start_detector {
    start_detector { 'configservers':
      ensure  => present,
      timeout => 120,
      servers => $mongos_configServers,
      policy  => one,
      before  => Service["mongos_${mongos_instance}"]
    }
  }

  if ($mongos_useauth != false) {
    file { "/etc/mongos_${mongos_instance}.key":
      content => template('mongodb/mongos.key.erb'),
      mode    => '0700',
      owner   => $::mongodb::params::run_as_user,
      require => Class['mongodb::install'],
      notify  => $notify,
    }
  }

  if ($mongos_service_manage == true) {
    service { "mongos_${mongos_instance}":
      ensure     => $mongos_running,
      enable     => $mongos_enable,
      hasstatus  => true,
      hasrestart => true,
      provider   => $service_provider,
      require    => [
        File[
          "/etc/mongos_${mongos_instance}.conf",
          "mongos_${mongos_instance}_service",
          $db_specific_dir]],
      before     => Anchor['mongodb::end'],
      subscribe  => $subscribe,
    }
  }

}
