#!/bin/sh
set -e

#Install Puppet Labs repositories.
if [ ! -f puppetlabs-release-trusty.deb ];
then
  wget "https://apt.puppetlabs.com/puppetlabs-release-trusty.deb"
  dpkg -i puppetlabs-release-trusty.deb
fi

apt-get update

#Clone our control repo
if [ ! -d /etc/puppet ];
then
  mkdir /etc/puppet
fi

cd /etc/puppet
#Install some dependencies
echo >&2 "Installing Dependencies.";
apt-get install git-core -y
apt-get install ruby -y
gem install deep_merge

#Install ActiveMQ 5.11.1 manually as 5.6.0 from ubuntu repository is broken.
if [ ! -d /usr/local/apache-activemq-5.11.1 ];
then
    echo >&2 "Installing ActiveMQ 5.11.1 ...";
    cd /tmp
    wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/activemq/5.11.1/apache-activemq-5.11.1-bin.tar.gz
    tar -zxvf apache-activemq-5.11.1-bin.tar.gz
    mv apache-activemq-5.11.1 /usr/local/
    ln -sf /usr/local/apache-activemq-5.11.1 /usr/local/activemq
    chown -R activemq /usr/local/apache-activemq-5.11.1/
    ln -sf /usr/local/activemq/bin/activemq /usr/bin/activemq
fi

#Test for eyaml.
command -v eyaml >/dev/null 2>&1 || {
                                      echo >&2 "Hiera-eyaml is required, but it is not installed.  Installing...";
                                      gem install hiera-eyaml
                                     }

#Test for R10k.
command -v r10k >/dev/null 2>&1 || {
                                      echo >&2 "R10k is required, but it is not installed.  Installing...";
                                      gem install r10k
                                     }


#Pull any updates.
if [ -d /etc/puppet/silex-puppet-control ];
then
    echo >&2 "Updating Silex Puppet control.";
    cd /etc/puppet/silex-puppet-control
    git pull origin vagrant
fi

#Test for Puppet Agent.
command -v puppet >/dev/null 2>&1 || {
                                      echo >&2 "Puppet Agent is required, but it is not installed.  Installing...";
                                      apt-get -y -f install puppet
                                     }

#Check if we have already cloned the repo.
if [ ! -d /etc/puppet/silex-puppet-control ];
then
    echo >&2 "Cloning the 'Control Repo'";
    cd /etc/puppet
    git clone https://github.com/j420n/silex-puppet-control.git
    echo >&2 "Checking out 'Vagrant' environment branch.";
    cd /etc/puppet/silex-puppet-control
    git checkout vagrant
fi

#Test for Puppet Master
if [ ! -f /etc/init.d/puppetmaster ];
then
   echo >&2 "Puppetmaster is required, but it is not installed.  Installing...";
   apt-get -y -f install puppetmaster
fi

#Test for PuppetDB
if [ ! -d /etc/puppetdb ];
then
    echo >&2 "PuppetDB is required, but it is not installed.  Installing...";
    apt-get -y install puppetdb
    apt-get -y install puppetdb-terminus
    echo >&2 "PuppetDB is Installed.";
fi

#Create Keys
echo >&2 "Creating Keys";

if [ ! -f /etc/puppet/silex-puppet-control/keys/private_key.pkcs7.pem ];
then
    cd /etc/puppet/silex-puppet-control/
    eyaml createkeys
fi

echo >&2 "Linking puppet configuration files.";

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

echo >&2 "Deploying 'VAGRANT' environment...";
r10k deploy environment vagrant -v

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

