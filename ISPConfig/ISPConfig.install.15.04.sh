#!/bin/bash

SetupBasic() {

   AptUpgrade # needs a new way to recheck if reboot have been made, before continue.

   package_install hostname landscape-common

   #Set hostname and FQDN
   SetNewHostname

   package_install vim-nox dnsutils unzip rkhunter binutils sudo bzip2 zip

   echo "dash dash/sh boolean false" | debconf-set-selections
   dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

   #Synchronize the System Clock
   package_install ntp ntpdate

}

DisableApparmor() {
   # Disable apparmor
   if [ -f /etc/init.d/apparmor ]; then
     /etc/init.d/apparmor stop
     update-rc.d -f apparmor remove
     packages_uninstall remove apparmor apparmor-utils
     rm /etc/init.d/apparmor
  fi
}

EnableMYSQL() {
   package_install software-properties-common python-software-properties

   echo "mysql-server mysql-server/root_password password $mysql_pass" | debconf-set-selections
   echo "mysql-server mysql-server/root_password_again password $mysql_pass" | debconf-set-selections

   package_install mariadb-server
   package_install mariadb-client 
   package_install php5-cli php5-mysqlnd php5-mcrypt mcrypt

   #Allow MySQL to listen on all interfaces
   cp /etc/mysql/mariadb.conf.d/mysqld.cnf /etc/mysql/mariadb.conf.d/mysqld.cnf.backup
   sed -i 's/bind-address/#bind-address/' /etc/mysql/mariadb.conf.d/mysqld.cnf
   /etc/init.d/mysql restart
}

EnableDovecot(){
   echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
   echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

   service sendmail stop; update-rc.d -f sendmail remove
   package_install postfix postfix-mysql postfix-doc openssl getmail4 dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve 

   cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
   sed -i 's|#submission inet n       -       -       -       -       smtpd|submission inet n       -       -       -       -       smtpd|' /etc/postfix/master.cf
   sed -i 's|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
   sed -i 's|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
   sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
   sed -i '/  -o smtpd_sasl_auth_enable=yes/i \  -o smtpd_client_restrictions=permit_sasl_authenticated,reject' /etc/postfix/master.cf
   sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
   sed -i 's|#smtps     inet  n       -       -       -       -       smtpd|smtps     inet  n       -       -       -       -       smtpd|' /etc/postfix/master.cf
   sed -i 's|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
   sed -i 's|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf
   sed -i "s/#  -o smtpd_reject_unlisted_recipient=no/  -o smtpd_reject_unlisted_recipient=yes/" /etc/postfix/master.cf

   /etc/init.d/postfix restart
}

EnableVirus() {
   packages_install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl heirloom-mailx
   service spamassassin stop
   update-rc.d -f spamassassin remove

   # we need to update clamd.conf & update clamav-scanner
   sed -i "s/AllowSupplementaryGroups false/AllowSupplementaryGroups true/" /etc/clamav/clamd.conf
   freshclam

   # Enable clamscan (daily) for www & vmail dirs.
   # note. this will produce errors for /var/www & /var/vmail
   # on first run we will need ispconfig to be done first.
   cd /etc/clamav/
   read -p "Please enter domain-name? " domain_name
   read -p "Please enter your email? " user_email
   cat > clamscan_daily.sh << EOF
#!/bin/bash
LOGFILE="/var/log/clamav/clamav-$(date +'%Y-%m-%d').log";
EMAIL_MSG="Please see the log file attached.";
EMAIL_FROM="clamav-daily@$domain_name";
EMAIL_TO="$user_email";
DIRTOSCAN="/var/www /var/vmail";

for S in ${DIRTOSCAN}; do
 DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);

 echo "Starting a daily scan of "$S" directory.
 Amount of data to be scanned is "$DIRSIZE".";

 clamscan -ri "$S" >> "$LOGFILE";

 # get the value of "Infected lines"
 MALWARE=$(tail "$LOGFILE"|grep Infected|cut -d" " -f3);

 # if the value is not equal to zero, send an email with the log file attached
 if [ "$MALWARE" -ne "0" ];then
 # using heirloom-mailx below
 echo "$EMAIL_MSG"|mail -a "$LOGFILE" -s "Malware Found" -r "$EMAIL_FROM" "$EMAIL_TO";
 fi
done

exit 0
EOF

   ln -s /etc/clamav/clamscan_daily.sh /etc/cron.daily/clamscan_daily
   chmod +x /etc/clamav/clamscan_daily.sh
   /etc/clamav/clamscan_daily.sh
   service clamav-daemon start
}

EnableApache() {
   #Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
   echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
   #BELOW ARE STILL NOT WORKING
   #echo 'phpmyadmin      phpmyadmin/dbconfig-reinstall   boolean false' | debconf-set-selections
   #echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

   package_install apache2 apache2-doc apache2-utils libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

   a2enmod suexec rewrite ssl actions include
   a2enmod dav_fs dav auth_digest

   cp /etc/apache2/conf-availble/suphp.conf /etc/apache2/conf-available/suphp.conf.backup
   cat > /etc/apache2/conf-available/suphp.conf <<EOF
    <IfModule mod_suphp.c>
        #<FilesMatch "\.ph(p3?|tml)$">
        #    SetHandler application/x-httpd-suphp
        #</FilesMatch>
            AddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml
            suPHP_AddHandler application/x-httpd-suphp
        <Directory />
            suPHP_Engine on
        </Directory>
        # By default, disable suPHP for debian packaged web applications as files
        # are owned by root and cannot be executed by suPHP because of min_uid.
        <Directory /usr/share>
            suPHP_Engine off
        </Directory>
    # # Use a specific php config file (a dir which contains a php.ini file)
    #       suPHP_ConfigPath /etc/php5/cgi/suphp/
    # # Tells mod_suphp NOT to handle requests with the type <mime-type>.
    #       suPHP_RemoveHandler <mime-type>
    </IfModule>
EOF
   sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types

   #Install X-Cache
   package_install php5-xcache
   service apache2 restart
}

EnableMailman() {

   echo "================================================================================================"
   echo "You will be prompted for some information during the install."
   echo "Select the languages you want to support and hit OK when told about the missing site list"
   echo "You will also be asked for the email address of person running the list & password for the list."
   echo "Please enter them where needed."
   echo "================================================================================================"
   echo "Press ENTER to continue.."
   read DUMMY

   #Install Mailman
   package_install mailman
   newlist mailman

   mv /etc/aliases /etc/aliases.backup

   cat > /etc/aliases.mailman <<EOF
   mailman:              "|/var/lib/mailman/mail/mailman post mailman"
   mailman-admin:        "|/var/lib/mailman/mail/mailman admin mailman"
   mailman-bounces:      "|/var/lib/mailman/mail/mailman bounces mailman"
   mailman-confirm:      "|/var/lib/mailman/mail/mailman confirm mailman"
   mailman-join:         "|/var/lib/mailman/mail/mailman join mailman"
   mailman-leave:        "|/var/lib/mailman/mail/mailman leave mailman"
   mailman-owner:        "|/var/lib/mailman/mail/mailman owner mailman"
   mailman-request:      "|/var/lib/mailman/mail/mailman request mailman"
   mailman-subscribe:    "|/var/lib/mailman/mail/mailman subscribe mailman"
   mailman-unsubscribe:  "|/var/lib/mailman/mail/mailman unsubscribe mailman"
EOF

   cat /etc/aliases.backup /etc/aliases.mailman > /etc/aliases
   newaliases
   /etc/init.d/postfix restart
   ln -s /etc/mailman/apache.conf /etc/apache2/conf-available/mailman.conf
   /etc/init.d/apache2 restart
   /etc/init.d/mailman start

}

EnablePureFTPD() {
   #Install PureFTPd
   package_install pure-ftpd-common pure-ftpd-mysql

   #Setting up Pure-Ftpd
   sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
   echo 1 > /etc/pure-ftpd/conf/TLS
   mkdir -p /etc/ssl/private/

   # enable pure-ftp passive ports
   echo 40110 40210 > /etc/pure-ftpd/conf/PassivePortRange

   # enable clamav scanner in pure-ftp
   echo "yes" > /etc/pure-ftpd/conf/CallUploadScript
   sed -i 's|UPLOADSCRIPT=|UPLOADSCRIPT=/etc/pure-ftpd/clamav_check.sh|' /etc/default/pure-ftpd-common
   cat > /etc/pure-ftpd/clamav_scan.sh <<EOF
#!/bin/sh
/usr/bin/clamdscan --remove --quiet --no-summary $1
EOF
   chmod 755 /ect/pure-ftpd/clamav_scan.sh

   # create ssl cert
   openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
   chmod 600 /etc/ssl/private/pure-ftpd.pem
   /etc/init.d/pure-ftpd-mysql restart

}

EnableQuota() {
   #Editing FStab
   cp /etc/fstab /etc/fstab.backup
   sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

   #Setting up Quota
   package_install quota quotatool
   mount -o remount /
   quotacheck -avugm
   quotaon -avug
}

EnableBind() {
   #Install BIND DNS Server
  package_install bind9 dnsutils
}

EnableStats() {
   package_install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

   sed -i "s/MAILTO=root/#MAILTO=root/" /etc/cron.d/awstats
   sed -i 's|*/10|#*/10|' /etc/cron.d/awstats
   sed -i "s/10 03 /#10 03 /" /etc/cron.d/awstats # note. this needs a new sed command since its kinda fucks up cron awstats
}

EnableJailkit() {
   package_install build-essential autoconf automake1.9 libtool flex bison debhelper binutils-gold

   cd /tmp
   wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz
   tar xvfz jailkit-2.17.tar.gz
   cd jailkit-2.17
   ./debian/rules binary
   cd ..
   dpkg -i jailkit_2.17-1_*.deb
   rm -rf jailkit-2.17*
}

EnableFail2ban() {
   package_install fail2ban
}

EnableFail2BanRulesDovecot() {
   cat > /etc/fail2ban/jail.local <<"EOF"
   [pureftpd]
   enabled  = true
   port     = ftp
   filter   = pureftpd
   logpath  = /var/log/syslog
   maxretry = 3
   [dovecot-pop3imap]
   enabled = true
   filter = dovecot-pop3imap
   action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
   logpath = /var/log/mail.log
   maxretry = 5
   [postfix-sasl]
   enabled  = true
   port     = smtp
   filter   = postfix-sasl
   logpath  = /var/log/mail.log
   maxretry = 3
EOF

   cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
   [Definition]
   failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
   ignoreregex =
EOF

   cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<"EOF"
   [Definition]
   failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
   ignoreregex =
EOF

   echo "ignoreregex =" >> /etc/fail2ban/filter.d/postfix-sasl.conf

   service fail2ban restart
}

EnableSquirrelMail() {

   echo "==========================================================================================="
   echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
   echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
   echo "==========================================================================================="
   echo "Press ENTER to continue.."
   read DUMMY
   #Install SquirrelMail
   package_install squirrelmail
   ln -s /usr/share/squirrelmail/ /var/www/webmail

   squirrelmail-configure
}

EnableISPConfig3() {
   #Install ISPConfig 3
   cd /tmp
   wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
   tar xfz ISPConfig-3-stable.tar.gz
   cd /tmp/ispconfig3_install/install/
   php -q install.php
}

EnableISPC_Clean() {
   cd /tmp
   wget https://github.com/dclardy64/ISPConfig_Clean-3.0.5/archive/master.zip
   unzip master.zip
   cd ISPConfig_Clean-3.0.5-master
   cp -R interface/* /usr/local/ispconfig/interface/

   sed -i "s|\$conf\['theme'\] = 'default'|\$conf\['theme'\] = 'ispc-clean'|" /usr/local/ispconfig/interface/lib/config.inc.php
   sed -i "s|\$conf\['logo'\] = 'themes/default|\$conf\['logo'\] = 'themes/ispc-clean|" /usr/local/ispconfig/interface/lib/config.inc.php
   mysql -u root -p$mysql_pass < sql/ispc-clean.sql
}

CheckISPConfig() {
   # check for previous install
   if [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
      echo "ISPConfig 3 is already installed!"
      exit 0
   fi
}

