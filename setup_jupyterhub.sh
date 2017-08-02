#!/bin/bash -e

#===============================================================================
# upgrade host OS
apt-get update
apt-get upgrade -y

#===============================================================================
# fix locals
#echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
#echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
#export LC_ALL=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8

# fix locals
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LC_ALL=en_US.UTF-8

#===============================================================================
# install Debdian packages
apt-get install -y       \
   python-pip            \
   python-setuptools     \
   python-wheel          \
   python3-pip           \
   python3-setuptools    \
   python3-wheel         \
   npm                   \
   nodejs-legacy         \
   apache2               \
   ntp

# install Node packages
npm install -g configurable-http-proxy

# install Python packages
pip3 install --upgrade             \
   pip                             \
   jupyterhub                      \
   dockerspawner                   \
   jupyterhub-hashauthenticator

#===============================================================================
# install Docker
#https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
usermod -aG docker ubuntu

#===============================================================================
# download configs
cd /opt
git clone https://github.com/oschuett/jupmatcloud.git

# configure apache
a2enmod ssl
a2enmod rewrite
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_wstunnel
ln -fs /opt/jupmatcloud/configs/apache_default.conf /etc/apache2/sites-available/000-default.conf
/etc/init.d/apache2 restart

#===============================================================================
# install letsencrypt
#TODO maybe do in a subshell because of the active
# cd /opt
# git clone https://github.com/certbot/certbot
# cd certbot
# ./letsencrypt-auto-source/letsencrypt-auto --os-packages-only
# ./tools/venv.sh
# source ./venv/bin/activate
# certbot certonly --renew-by-default --non-interactive --webroot --rsa-key-size 4096 --agree-tos --email info@jupyter.materialscloud.org --webroot-path /var/www/letsencrypt/ -d jupyter.materialscloud.org

#===============================================================================
# install SwitchAAI
# https://www.switch.ch/aai/guides/sp/installation/?os=ubuntu
curl -fsSL http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc | apt-key add -
echo 'deb http://pkg.switch.ch/switchaai/ubuntu xenial main' > /etc/apt/sources.list.d/SWITCHaai-swdistrib.list
apt-get update
apt-get install -y --install-recommends shibboleth
ln -sf  /opt/jupmatcloud/shibboleth/* /etc/shibboleth/

#TODO: Upload  sp-cert.pem sp-key.pem

#===============================================================================
# restart apache2 with SSL
ln -fs /opt/jupmatcloud/configs/apache_jupyter.materialscloud.org.conf /etc/apache2/sites-available/jupyter.materialscloud.org.conf
a2ensite jupyter.materialscloud.org
/etc/init.d/apache2 restart

#===============================================================================
# configure JupyterHub
export CONFIGPROXY_AUTH_TOKEN=`openssl rand -hex 32`


#EOF