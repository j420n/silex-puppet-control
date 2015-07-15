#This file should be in /etc/puppet/environments/$environment/
hiera_include('classes')
class profile::default {
  #This is only used to include "Dynamic configuration" created with hiera.
  notify { "The profile::default class is included by 'default' to include classes defined by hiera.": withpath => true }
}
