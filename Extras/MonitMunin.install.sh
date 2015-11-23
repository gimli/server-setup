#!/bin/bash
#------------------------------------------------------------------#
# this script will helpp you setup Munin & Monit stats on your     #
# Environment. at the end of the script you will be able to use    #
# http://domain.com/monit & http://domain.com:2812/ to see your    #
# server status.                                                   #
# - Ubuntu Server Automated Installer                              #
# - Author: Nickless - admin@isengard.dk                           #
# - Link:                                                          #
#------------------------------------------------------------------#

EnableMonit(){

   echo "we need just abit infomation from you ? ;)"
   echo "your@email.com, the domain name of monit server."
   echo "and last the password you wont to access your server."
   read -p "Email: " user_email
   read -p "Domain: " domain_name
   read -p "Username: " user_name
   read -p "Password: " user_password

   apt-get update
   apt-get upgrade

   apt-get install monit

   cp /etc/monit/monitrc /etc/monit/monitrc_orig
   cat /dev/null > /etc/monit/monitrc
   cat > /etc/monit/monitrc <<EOF
set daemon 60
set logfile syslog facility log_daemon
set mailserver localhost
set mail-format { from: monit@$domain_name }
set alert $user_email
set httpd port 2812 and
 SSL ENABLE
 PEMFILE /var/certs/monit.pem
 allow $user_name:$user_password

check process sshd with pidfile /var/run/sshd.pid
 start program "/usr/sbin/service ssh start"
 stop program "/usr/sbin/service ssh stop"
 if failed port 22 protocol ssh then restart
 if 5 restarts within 5 cycles then timeout

check process apache with pidfile /var/run/apache2/apache2.pid
 group www
 start program = "/usr/sbin/service apache2 start"
 stop program = "/usr/sbin/service apache2 stop"
 if failed host localhost port 80 protocol http
 and request "/monit/token" then restart
 if cpu is greater than 60% for 2 cycles then alert
 if cpu > 80% for 5 cycles then restart
 if totalmem > 1024 MB for 5 cycles then restart
 if children > 250 then restart
 if loadavg(5min) greater than 10 for 8 cycles then stop
 if 3 restarts within 5 cycles then timeout
 
# ---------------------------------------------------------------------------------------------
# NOTE: Replace example.pid with the pid name of your server, the name depends on the hostname
# ---------------------------------------------------------------------------------------------
check process mysql with pidfile /var/run/mysqld/mysqld.pid
 group database
 start program = "/usr/sbin/service mysql start"
 stop program = "/usr/sbin/service mysql stop"
 if failed host 127.0.0.1 port 3306 then restart
 if 5 restarts within 5 cycles then timeout
check process postfix with pidfile /var/spool/postfix/pid/master.pid
 group mail
 start program = "/usr/sbin/service postfix start"
 stop program = "/usr/sbin/service postfix stop"
 if failed port 25 protocol smtp then restart
 if 5 restarts within 5 cycles then timeout
#
#check process nginx with pidfile /var/run/nginx.pid
# start program = "/usr/sbin/service nginx start"
# stop program = "/usr/sbin/service nginx stop"
# if failed host 127.0.0.1 port 80 then restart
#
check process memcached with pidfile /var/run/memcached.pid
 start program = "/usr/sbin/service memcached start"
 stop program = "/usr/sbin/service memcached stop"
 if failed host 127.0.0.1 port 11211 then restart
check process pureftpd with pidfile /var/run/pure-ftpd/pure-ftpd.pid
 start program = "/usr/sbin/service pure-ftpd-mysql start"
 stop program = "/usr/sbin/service pure-ftpd-mysql stop"
 if failed port 21 protocol ftp then restart
 if 5 restarts within 5 cycles then timeout
check process named with pidfile /var/run/named/named.pid
 start program = "/usr/sbin/service bind9 start"
 stop program = "/usr/sbin/service bind9 stop"
 if failed host 127.0.0.1 port 53 type tcp protocol dns then restart
 if failed host 127.0.0.1 port 53 type udp protocol dns then restart
 if 5 restarts within 5 cycles then timeout
check process ntpd with pidfile /var/run/ntpd.pid
 start program = "/usr/sbin/service ntp start"
 stop program = "/usr/sbin/service ntp stop"
 if failed host 127.0.0.1 port 123 type udp then restart
 if 5 restarts within 5 cycles then timeout
check process mailman with pidfile /var/run/mailman/mailman.pid
 group mail
 start program = "/usr/sbin/service mailman start"
 stop program = "/usr/sbin/service mailman stop"
check process amavisd with pidfile /var/run/amavis/amavisd.pid
 group mail
 start program = "/usr/sbin/service amavis start"
 stop program = "/usr/sbin/service amavis stop"
 if failed port 10024 protocol smtp then restart
 if 5 restarts within 5 cycles then timeout
check process dovecot with pidfile /var/run/dovecot/master.pid
 group mail
 start program = "/usr/sbin/service dovecot start"
 stop program = "/usr/sbin/service dovecot stop"
 #if failed host localhost port 993 type tcpssl sslauto protocol imap then restart
 if failed host localhost port 143 type tcp protocol imap then restart
 if 5 restarts within 5 cycles then timeout
EOF

 mkdir /var/www/html/monit
 echo "hello" /var/www/html/monit/token

 mkdir /var/certs
 cd /var/certs

 cat > /var/certs/monit.cnf <<EOF
# create RSA certs - Server

RANDFILE = ./openssl.rnd

[ req ]
default_bits = 2048
encrypt_key = yes
distinguished_name = req_dn
x509_extensions = cert_type

[ req_dn ]
countryName = Country Name (2 letter code)
countryName_default = MO

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Monitoria

localityName                    = Locality Name (eg, city)
localityName_default            = Monittown

organizationName                = Organization Name (eg, company)
organizationName_default        = Monit Inc.

organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = Dept. of Monitoring Technologies

commonName                      = Common Name (FQDN of your server)
commonName_default              = server.monit.mo

emailAddress                    = Email Address
emailAddress_default            = root@monit.mo

[ cert_type ]
nsCertType = server
EOF

   openssl req -new -x509 -days 365 -nodes -config ./monit.cnf -out /var/certs/monit.pem -keyout /var/certs/monit.pem
   openssl gendh 1024 >> /var/certs/monit.pem
   openssl x509 -subject -dates -fingerprint -noout -in /var/certs/monit.pem
   chmod 600 /var/certs/monit.pem

   service monit start
   service monit restart
}

EnableMunin(){

   apt-get update
   apt-get dist-upgrade

   a2enmod fcgid
   apt-get install munin munin-node munin-plugins-extra

   sed -i "s/#dbdir/dbdir/" /etc/munin/munin.conf
   sed -i "s/#htmldir/htmldir/" /etc/munin/munin.conf
   sed -i "s/#logdir/logdir/" /etc/munin/munin.conf
   sed -i "s/#rundir/rundir" /etc/munin/munin.conf
   sed -i "s/#tmpldir/tmpldir" /etc/munin/munin.conf
   sed -i 's/server1.example.com/$HOSTNAMEFQDN/' /etc/munin/munin.conf

   mv /etc/munin/apache24.conf /etc/munin/apache24.conf.original
   cat > /etc/munin/apache24.conf <<EOF
Alias /munin /var/cache/munin/www
<Directory /var/cache/munin/www>
 # Require local
 # Require all granted
 AuthUserFile /etc/munin/munin-htpasswd
 AuthName "Munin"
 AuthType Basic
 Require valid-user
 Options None
</Directory>

ScriptAlias /munin-cgi/munin-cgi-graph /usr/lib/munin/cgi/munin-cgi-graph
<Location /munin-cgi/munin-cgi-graph>
 # Require local
 # Require all granted
 AuthUserFile /etc/munin/munin-htpasswd
 AuthName "Munin"
 AuthType Basic
 Require valid-user
 <IfModule mod_fcgid.c>
 SetHandler fcgid-script
 </IfModule>
 <IfModule !mod_fcgid.c>
 SetHandler cgi-script
 </IfModule>
</Location>
EOF

   cd /etc/apache2/conf-enabled/
   ln -s /etc/munin/apache24.conf munin.conf

   service apache2 restart
   service munin-node restart

   htpasswd -c /etc/munin/munin-htpasswd admin
   service apache2 restart
   munin-node-configure --suggest
   cd /etc/munin/plugins

   #these doesnt seems to be nessary anyways on ubuntu
   #ln -s /usr/share/munin/plugins/apache_accesses
   #ln -s /usr/share/munin/plugins/apache_processes
   #ln -s /usr/share/munin/plugins/apache_volume

   service munin-node restart
}
