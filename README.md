Silex Puppet Control
====================
>
>This is the master "Control Repo" which has the configuration to manage all nodes in your infrastructure.

>This repo can be branched into multiple Puppet Environments and utilise r10k to deploy them for you.
>It would require just a single command to be manually issued on each of your servers...
>Unless you have the Marionette Collective do that for you instead.
>Well, actually 3 on the first run.

    curl -O https://raw.githubusercontent.com/j420n/silex-puppet-control/master/provision.sh > provision.sh
    chmod u+x ./provision.sh
    ./provision-dev.sh

>To test this out you could use our [debian8-xen] repo which will deploy a base system for this control repo.
>
>All you need to do is "git clone [debian8-xen]" and "vagrant up".
>If that doesn't work try install git and vagrant.
>If that does not work, please open a pull request!
>Thanks for Reading.

[debian8-xen]: https://github.com/j420n/vagrant-debian8-xen.git