#Silex Puppet Control Profiles
#This file should be in /etc/puppet/environments/$environment/
#Include classes with hiera.
hiera_include('classes')

#DEFAULT PROFILE
#Create a default class for all nodes.
class profile::default {
  #This is only used to include "Dynamic configuration" created with hiera.
  notify { "The profile::default class is included by 'default'.": withpath => true }
}

#XEN PROFILE
class profile::xen {
  notify { "The profile::xen class installs a few packages to get started with a Xen Linux System.": withpath => true }
  notify { "To make full use of the Xen Linux System, You will need to reboot and load the Xen kernel.":}

  #TODO move these packages into a module.
  #Install xen-linux-system.
  package { "xen-linux-system":
    ensure => "installed"
  }
  #Install xen-tools.
  package { "xen-tools":
    ensure => "installed"
  }
  #Install DHCP daemon.
  package { "udhcpd":
    ensure => "installed"
  }
  #Install DNS server.
  package { "bind9":
    ensure => "installed"
  }
}

#DEV PROFILE
class profile::dev {
  notify { "The profile::dev class is un-used, All the configuration is set with hiera.": withpath => true }
}

#VPS PROFILE
class profile::vps {
  notify { "The profile::vps class is un-used, All the configuration is set with hiera.": withpath => true }
}



