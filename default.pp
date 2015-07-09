#This file should be in /etc/puppet/environments/production/
hiera_include('classes')
class profile::default {
#This is only used to include "Dynamic configuration" created with hiera.
notify { "The profile::default class is included by 'default'": withpath => true }
}