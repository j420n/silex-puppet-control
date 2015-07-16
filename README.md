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
>All you need to do is:
    git clone [debian8-xen]
    cd vagrant-debian8-xen
    vagrant up

>If that doesn't work try install git/vagrant.
>If that does not work, please open a pull request after fixing the problem ;-) !
>Thanks for Reading.

###To Change from the vagrant environment to production you can run the following.

    sed -i "/vagrant/c\production" /etc/puppet/silex-puppet-control/provision.sh
    sed -i "/vagrant/c\production" /etc/puppet/silex-puppet-control/environment.conf
    sed -i "/vagrant/c\production"/etc/puppet/silex-puppet-control/puppet.conf

>After running the above commands, you will need to commit the changes in a new branch named after you environment:

    git commit -am "Updates for new production environment branch."
    git branch production
    git push origin production
    ./provision.sh
    OR
    r10k deploy environment production
    service puppetmaster restart
