Silex Puppet Control
====================
>
>This is the master "Control Repo" which has the configuration to manage all nodes in your infrastructure.

>This repo can be branched into multiple Puppet Environments and utilise r10k to deploy them for you.
>It would require just a single command to be manually issued on each of your servers...
>Unless you have the Marionette Collective do that for you instead.
>Well, actually 3 on the first run.

    curl -O https://raw.githubusercontent.com/j420n/silex-puppet-control/production/provision.sh > provision.sh
    chmod u+x ./provision.sh
    ./provision-dev.sh

>To test this out you could use our [vagrant-debian8] repo which will deploy a base system for this control repo.
>
>All you need to do is:
    git clone [vagrant-debian8]
    cd vagrant-debian8
    vagrant up

>If that doesn't work try install git/vagrant.
>If that does not work, please open a pull request after fixing the problem ;-) !
>Thanks for Reading.

###To Change from production to a new environment you can run the following.

    sed -i "/production/c\<branch name>" /etc/puppet/silex-puppet-control/provision.sh
    sed -i "/production/c\<branch name>" /etc/puppet/silex-puppet-control/environment.conf
    sed -i "/production/c\<branch name>"/etc/puppet/silex-puppet-control/puppet.conf

>After running the above commands, you will need to commit the changes in a new branch named after your environment:

    git commit -am "Updates for new <branch name> environment branch."
    git branch <branch name>
    git push origin <branch name>
    ./provision.sh
    OR
    r10k deploy environment <branch name>
    service puppetmaster restart

[vagrant-debian8]: https://github.com/j420n/vagrant-debian8.git
