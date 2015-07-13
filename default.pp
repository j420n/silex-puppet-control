#This file should be in /etc/puppet/environments/production/
hiera_include('classes')
class profile::default {
#This is only used to include "Dynamic configuration" created with hiera.
notify { "The profile::default class is included by 'default'": withpath => true }

  #Install xen-linux-system.
  package { "xen-linux-system":
  ensure => "installed"
  }

  #Install xen-tools.
  package { "xen-tools":
  ensure => "installed"
  }

}
