#This file should be in /etc/puppet/environments/$environment/

notify { "The profile::xen class installs a few packages to get started with a Xen Linux System.": withpath => true }
notify { "To make full use of the Xen Linux System, You will need to reboot and load the Xen kernel."}

class profile::xen {
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
