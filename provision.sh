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

apt-get update

#Install some dependencies
echo >&2 "Installing git-core and deep_merge.";
apt-get install git-core hiera-eyaml -y
gem install deep_merge

INSTALL_MASTER=true;
INSTALL_AGENT=true;
INSTALL_ACTIVEMQ=true;
INSTALL_DOCKER=false;
HOSTNAME=debian8-xen;
DOMAINNAME=local.ghost;

install_master() {
    #Test for Puppet Master
    #Comment this out if you dont want a puppetmaster service.
    if [ ! -f /etc/init.d/puppetmaster ];
    then
       echo >&2 "Puppetmaster is required, but it is not installed.  Installing...";
       apt-get -y -f install puppetmaster=3.7.2-4;
    fi

    #Test for PuppetDB
    #Comment this out if you dont want a puppetdb service.
    if [ ! -d /etc/puppetdb ];
    then
        echo >&2 "PuppetDB is required, but it is not installed.  Installing...";
        apt-get -y install puppetdb=2.3.5-1puppetlabs1;
        echo >&2 "PuppetDB is Installed.";
    fi
    #Configure Jetty host and port for puppetdb.
    sed -i 's/# host = <host>/host = 127.0.1.1/g' /etc/puppetdb/conf.d/jetty.ini
    sed -i 's/port = 8080/port = 8980/g' /etc/puppetdb/conf.d/jetty.ini
    sed -i 's/# ssl-host = <host>/ssl-host = 0.0.0.0/g' /etc/puppetdb/conf.d/jetty.ini
    sed -i 's/# ssl-port = <port>/ssl-port = 8981/g' /etc/puppetdb/conf.d/jetty.ini
    sed -i 's/ssl-port = 8081/ssl-port = 8981/g' /etc/puppetdb/conf.d/jetty.ini
    echo >&2 "Do these PuppetDb settings look right?";
    cat /etc/puppetdb/conf.d/jetty.ini | grep ssl-host
    cat /etc/puppetdb/conf.d/jetty.ini | grep ssl-port
}

install_agent() {
#Test for Puppet Agent.
    command -v puppet >/dev/null 2>&1 || {
      echo >&2 "Puppet Agent is required, but it is not installed.  Installing...";
      apt-get -y -f install puppet=3.7.2-4;
     }
    #Test for PuppetDB Terminus
    #Comment this out if you dont want a puppetdb service.
    if [ ! -d /etc/puppetdb ];
    then
        echo >&2 "PuppetDB Terminus is required, but it is not installed.  Installing...";
        apt-get -y install puppetdb-terminus=2.3.5-1puppetlabs1;
        echo >&2 "PuppetDB Terminus is Installed.";
    fi
}

install_docker() {
    #INSTALL DOCKER MANUALLY AS IT IS NOT AVAILABLE IN DEBIAN 8 yet. https://lists.debian.org/debian-release/2015/03/msg00685.html
    if [ -f /etc/apt/sources.list.d/docker.list ]
    then
      rm /etc/apt/sources.list.d/docker.list;
    fi
    touch /etc/apt/sources.list.d/docker.list
    echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list.d/docker.list
    #Replace incorrect sources url which is created by puppet docker module.
    #sed -i "/deb https:\/\/get.docker.com\/ubuntu docker main*/c\deb http:\/\/http.debian.net\/debian jessie-backports main" /etc/apt/sources.list.d/docker.list
    #Install docker.io using jessie-backports
    echo >&2 "Installing Docker.io...";
    apt-get update
    apt-get -t jessie-backports install "docker.io" -y
    ln -sf /usr/bin/docker.io /usr/bin/docker
}

install_activemq() {
    #Install ActiveMQ 5.11.2 manually as 5.6.0 from debian repository is broken.
    command -v activemq >/dev/null 2>&1 || {
        echo >&2 "Installing ActiveMQ...";
        cd /tmp
        if [ ! -f apache-activemq-5.11.2-bin.tar.gz ]
          then
            wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/activemq/5.11.2/apache-activemq-5.11.2-bin.tar.gz
            tar -zxvf apache-activemq-5.11.2-bin.tar.gz
        fi
        if [ -d apache-activemq-5.11.2-bin ]
          then
            mv apache-activemq-5.11.2 /usr/local/
            ln -sf /usr/local/apache-activemq-5.11.2 /usr/local/activemq
            chown -R activemq: /usr/local/apache-activemq-5.11.2/
            ln -sf /usr/local/activemq/bin/activemq /usr/bin/activemq
        fi
    }

}

#Set domainname manually as vagrant will only set hostname and uses the domain of the router.
sed -i '/127.0.1.1 */d' /etc/hosts
echo "127.0.1.1 $HOSTNAME.$DOMAINNAME $HOSTNAME" >> /etc/hosts

if [ ${INSTALL_AGENT} ];
then
install_agent
fi

if [ ${INSTALL_MASTER} ];
then
install_master
fi

if [ ${INSTALL_DOCKER} ];
then
install_docker
fi

if [ ${INSTALL_ACTIVEMQ} ];
then
install_activemq
fi


#Replace certname in puppet.conf.
sed -i "/certname = */c\certname = $(facter fqdn)" /etc/puppet/puppet.conf

#Pull any updates.
if [ -d /etc/puppet/silex-puppet-control ];
then
    echo >&2 "Updating Silex Puppet control.";
    cd /etc/puppet/silex-puppet-control
    git pull origin vagrant
fi

#Check if we have already cloned the repo.
if [ ! -d /etc/puppet/silex-puppet-control ] && [ -d /etc/puppet ];
then
    echo >&2 "Cloning the 'Control Repo'";
    cd /etc/puppet
    git clone https://github.com/j420n/silex-puppet-control.git
    echo >&2 "Checking out 'VAGRANT' environment branch.";
    cd /etc/puppet/silex-puppet-control
    git checkout vagrant
fi

if [ ! -f /etc/puppet/silex-puppet-control/keys/private_key.pkcs7.pem ];
then
    #Create Keys
    echo >&2 "Creating Keys";
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

echo >&2 "Deploying 'VAGRANT' environment...";
r10k deploy environment vagrant
echo >&2 "Restarting Services";

if [ -f /etc/init.d/puppetmaster ];
then
    echo >&2 "The local Puppet Master has been found. Welcome to the Puppet show.";
    /etc/init.d/puppetmaster restart;
fi

if [ -f /etc/init.d/puppetdb ];
then
    puppetdb ssl-setup
    /etc/init.d/puppetdb restart;
    /etc/init.d/puppetqd restart;
    echo >&2 "Waiting 30 seconds for PuppetDB to start.";
    until netstat -antpu | grep 8981;
      do sleep 30;
    done
fi

echo >&2 "Running Puppet Agent.";
puppet agent --enable
puppet agent -t

