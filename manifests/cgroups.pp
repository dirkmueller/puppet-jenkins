# == Class: jenkins::cgroups
#
class jenkins::cgroups {

  include ::jenkins::params

  if ($::jenkins::params::cgroups_tools_package != '') {
    package { 'cgroups-tools':
      ensure => present,
      name   => $::jenkins::params::cgroups_tools_package,
    }
  }
  package { 'cgroups':
    ensure => present,
    name   => $::jenkins::params::cgroups_package,
  }

  file { '/etc/cgconfig.conf':
    ensure  => present,
    replace => true,
    owner   => 'root',
    group   => 'jenkins',
    mode    => '0644',
    content => template('jenkins/cgconfig.erb'),
  }

  file { '/etc/cgrules.conf':
    ensure  => present,
    replace => true,
    owner   => 'root',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/jenkins/cgroups/cgrules.conf',
  }

  if $::osfamily == 'Debian' {
    # 14.04 and below is using upstart.
    if $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '14.04') <= 0 {
      file { 'cgconfig.service':
        ensure  => present,
        replace => true,
        owner   => 'root',
        path    => '/etc/init/cgconfig.conf',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/upstart_cgconfig',
      }

      file { '/etc/init.d/cgconfig':
        ensure => link,
        target => '/lib/init/upstart-job',
      }

      file { 'cgred.service':
        ensure  => present,
        replace => true,
        owner   => 'root',
        path    => '/etc/init/cgred.conf',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/upstart_cgred',
      }

      file { '/etc/init.d/cgred':
        ensure => link,
        target => '/lib/init/upstart-job',
      }
    } else {
      file { 'cgred.service':
        ensure  => present,
        replace => true,
        owner   => 'root',
        path    => '/etc/systemd/system/cgred.service',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/cgred.service',
      }

      file { 'cgconfig.service':
        ensure  => present,
        replace => true,
        owner   => 'root',
        path    => '/etc/systemd/system/cgconfig.service',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/cgconfig.service',
      }
    }
  }

  service { 'cgconfig':
    ensure    => running,
    enable    => true,
    require   => $::jenkins::params::cgconfig_require,
    subscribe => File['/etc/cgconfig.conf'],
  }

  service { 'cgred':
    ensure    => running,
    enable    => true,
    require   => $::jenkins::params::cgred_require,
    subscribe => File['/etc/cgrules.conf'],
  }
}
