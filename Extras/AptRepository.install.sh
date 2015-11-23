#!/bin/bash
#-------------------------------------------------------#
# this script will help you setup reprepro APT repo.    #
# here we will download and setup public APT repo..     #
# Create a public key and a simple script that will     #
# automaticly update repo's simply add it to cron.      #
# deb http://apt.domain.com/debian vivid main           #
# - Ubuntu Server Automated Installer                   #
# - Author: Nickless - admin@isengard.dk                #
# - Liink:                                              #
#-------------------------------------------------------#

EnableAPTRepo(){

   apt-get install gnupg rng-tools reprepro dpkg-sig
   sed -i "s|#HRNGDEVICE=/dev/hwrng|HRNGDEVICE=/dev/urandom|" /etc/default/rng-tools
   /etc/init.d/rng-tools start
   gpg --gen-key
   mkdir -p /var/packages/debian/conf
   gpg --list-keys
   echo "Please write down your public id down, we gonna need it!"
   sleep 10
   read -p "Please enter your domain name? : " domain_name
   read -p "Please enter your distribution? : " code_name
   read -p "Please enter a repo desc? : " desc
   read -p "Please enter your public key? : " key
   cat /var/packages/debian/conf/distributions <<<EOF
Origin: apt.$domain_name
Label: apt.$domain_name
Codename: $code_nae
Architectures: i386 amd64
Components: main
Description: $desc
SignWith: $key
DebOverride: override.$code_name
DscOverride: override.$code_name
EOF

  touch /var/packages/debian/conf/override.$code_name
  cat /var/packages/debian/conf/options <<<EOF
verbose
ask-passphrase
basedir /var/packages/debian
EOF

  gpg --armor --output /var/packages/apt.$domain_name.gpg.key --export $key
  echo "deb http://apt.$domain_name/debian $code_name main" >> /etc/apt/sources.list.d/repo.list
  wget -O - -q http://apt.$domain_name/apt.$domain_name.gpg.key | apt-key add -

  # Install apache configuration not this config is for apache2.4
  cat /etc/apache2/conf-enabled/apt.conf <<EOF
lias /apt /var/packages

<VirtualHost *:80>
ServerName apt.$domain_name
Alias /apt /var/packages

DocumentRoot /var/packages/
<Directory /var/packages>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Require all granted
</Directory>
</VirtualHost>
EOF
  service apache2 restart
  mkdir -p /root/repo
  echo "Please put one or serval .debs in /root/repo, before updating public repo."
  read DUMMY

  cd /var/packages/debian
  reprepro includedeb $code_name /root/repo/*.deb
  reprepro -Vb . export

  cat /root/update_repo.sh <<<EOF
#!/bin/bash
# Simple way to update your repo, can also be used for cron
# also make sure u didnt enter a password when generating public
# keys.

cd /var/packages/debian
reprepro includedeb $code_name /root/repo/*.deb
reprepro -Vb . export
EOF
  chmod +x /root/update_repo.sh
}
