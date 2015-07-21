#!/bin/sh
set -e

#Install Puppet Labs repositories.
if [ ! -f puppetlabs-release-pc1-wheezy.deb ];
then
#TODO Change to jessie repo when puppet 4
  wget "https://apt.puppetlabs.com/puppetlabs-release-pc1-jessie.deb"
  dpkg -i puppetlabs-release-pc1-jessie.deb
  wget "https://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb"
  dpkg -i puppetlabs-release-pc1-wheezy.deb
fi

#INSTALL DOCKER MANUALLY AS IT IS NOT AVAILABLE IN DEBIAN 8 yet. https://lists.debian.org/debian-release/2015/03/msg00685.html
#Replace incorrect sources url which is created by puppet docker module.
#sed -i "/deb https:\/\/get.docker.com\/ubuntu docker main*/c\deb http:\/\/http.debian.net\/debian jessie-backports main" /etc/apt/sources.list.d/docker.list

apt-get update

#Install docker.io using jessie-backports
#apt-get -t jessie-backports install "docker.io"

#Clone our control repo
cd /etc/puppet
#Install some dependencies
echo >&2 "Installing git-core and deep_merge.";
apt-get install git-core hiera-eyaml -y
gem install deep_merge

#Pull any updates.
if [ -d /etc/puppet/silex-puppet-control ];
then
    echo >&2 "Updating Silex Puppet control.";
    cd /etc/puppet/silex-puppet-control
    git pull origin production
fi

#Test for Puppet Agent.
command -v puppet >/dev/null 2>&1 || {
                                      echo >&2 "Puppet Agent is required, but it is not installed.  Installing...";
                                      apt-get -y -f install puppet=3.7.2-4;
                                     }

#Check if we have already cloned the repo.
if [ ! -d /etc/puppet/silex-puppet-control ];
then
    echo >&2 "Cloning the 'Control Repo'";
    cd /etc/puppet
    git clone https://github.com/j420n/silex-puppet-control.git
    echo >&2 "Checking out 'PRODUCTION' environment branch.";
    cd /etc/puppet/silex-puppet-control
    git checkout production
fi

#Test for Puppet Master
if [ ! -f /etc/init.d/puppetmaster ];
then
   echo >&2 "Puppetmaster is required, but it is not installed.  Installing...";
   apt-get -y -f install puppetmaster=3.7.2-4;
fi

#Test for PuppetDB
if [ ! -d /etc/puppetdb ];
then
    echo >&2 "PuppetDB is required, but it is not installed.  Installing...";
    apt-get -y install puppetdb=2.3.5-1puppetlabs1;
    apt-get -y install puppetdb-terminus=2.3.5-1puppetlabs1;
    echo >&2 "PuppetDB is Installed.";
fi

#Create Keys
echo >&2 "Creating Keys";

if [ ! -f /etc/puppet/silex-puppet-control/keys/private_key.pkcs7.pem ];
then
    cd /etc/puppet/silex-puppet-control/
    eyaml createkeys
fi

echo >&2 "Installing r10k and linking puppet configuration files.";
#Install r10k from Debian repo.
apt-get install r10k -y

#Symlink hiera, puppet and r10k configuration from the control repo.
rm -f /etc/puppet/hiera.yaml
rm -f /etc/hiera.yaml
rm -f /etc/r10k.yaml
rm -f /etc/puppet/puppet.conf
rm -f /etc/puppet/puppetdb.conf
ln -sf /etc/puppet/silex-puppet-control/hiera.yaml /etc/puppet/
ln -sf /etc/puppet/silex-puppet-control/hiera.yaml /etc/
ln -sf /etc/puppet/silex-puppet-control/r10k.yaml /etc/
ln -sf /etc/puppet/silex-puppet-control/puppet.conf /etc/puppet/
ln -sf /etc/puppet/silex-puppet-control/puppetdb.conf /etc/puppet/
ln -sf /etc/puppet/silex-puppet-control/environment.conf /etc/puppet/

echo >&2 "Deploying 'PRODUCTION' environment...";
r10k deploy environment production

#Configure Jetty host and port for puppetdb.
sed -i 's/# host = <host>/host = 127.0.1.1/g' /etc/puppetdb/conf.d/jetty.ini
sed -i 's/port = 8080/port = 8980/g' /etc/puppetdb/conf.d/jetty.ini
sed -i 's/# ssl-host = <host>/ssl-host = 0.0.0.0/g' /etc/puppetdb/conf.d/jetty.ini
sed -i 's/# ssl-port = <port>/ssl-port = 8981/g' /etc/puppetdb/conf.d/jetty.ini
sed -i 's/ssl-port = 8081/ssl-port = 8981/g' /etc/puppetdb/conf.d/jetty.ini
echo >&2 "Does this look right?";
cat /etc/puppetdb/conf.d/jetty.ini | grep ssl-host
cat /etc/puppetdb/conf.d/jetty.ini | grep ssl-port

#Replace certname in puppet.conf.
sed -i "/certname = */c\certname = $(facter fqdn)" /etc/puppet/puppet.conf

if [ -f /etc/init.d/puppetmaster ];
then
    echo >&2 "The local Puppet Master has been found. Welcome to the Puppet show.";
    /etc/init.d/puppetdb restart;
    /etc/init.d/puppetmaster restart;
    /etc/init.d/puppetqd restart;
    puppet agent --enable
    puppetdb ssl-setup
fi

echo >&2 "Waiting 30 seconds for PuppetDB to start.";
until netstat -antpu | grep 8981;
  do sleep 30;
done

echo >&2 "Running Puppet Agent.";
puppet agent -t

