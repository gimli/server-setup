#!/bin/bash

EnableRoundcube(){
    packages=("wget" "nano")
    for i in "${packages[@]}"
    do
	echo "Installing $i.."
        package_install $i
    done
    mkdir /opt/roundcube
    cd /opt/roundcube
    wget https://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.1.3/roundcubemail-1.1.3-complete.tar.gz
    tar xfz roundcubemail-1.1.3-complete.tar.gz
    mv roundcubemail-1.1.3/* .
    mv roundcubemail-1.1.3/.htaccess .
    rmdir roundcubemail-1.1.3
    rm roundcubemail-1.1.3-complete.tar.gz
    chown -R www-data:www-data /opt/roundcube
    cat > create_db.sql <<EOF
CREATE DATABASE roundcube;
GRANT ALL PRIVILEGES ON roundcube.* TO roundcube@localhost IDENTIFIED BY 'secretpassword';
flush privileges;
quit
EOF
}
    mysql -u root -p < create_db.sql
    mysql -u root -p roundcube < /opt/roundcube/SQL/mysql.initial.sql
    cd /opt/roundcube/config
    cp -pf config.inc.php.sample config.inc.php
    sed -i "s/roundcube:password/roundcube:secretpassword@localhost/" config.inc.php
    cd /etc/apache2/conf-available/
    cat > roundcube.conf <<EOF
Alias /roundcube /opt/roundcube
Alias /webmail /opt/roundcube

<Directory /opt/roundcube>
 Options +FollowSymLinks
 # AddDefaultCharset UTF-8
 AddType text/x-component .htc
 
 <IfModule mod_php5.c>
 AddType application/x-httpd-php .php
 php_flag display_errors Off
 php_flag log_errors On
 # php_value error_log logs/errors
 php_value upload_max_filesize 10M
 php_value post_max_size 12M
 php_value memory_limit 64M
 php_flag zlib.output_compression Off
 php_flag magic_quotes_gpc Off
 php_flag magic_quotes_runtime Off
 php_flag zend.ze1_compatibility_mode Off
 php_flag suhosin.session.encrypt Off
 #php_value session.cookie_path /
 php_flag session.auto_start Off
 php_value session.gc_maxlifetime 21600
 php_value session.gc_divisor 500
 php_value session.gc_probability 1
 </IfModule>

 <IfModule mod_rewrite.c>
 RewriteEngine On
 RewriteRule ^favicon\.ico$ skins/larry/images/favicon.ico
 # security rules:
 # - deny access to files not containing a dot or starting with a dot
 # in all locations except installer directory
 RewriteRule ^(?!installer)(\.?[^\.]+)$ - [F]
 # - deny access to some locations
 RewriteRule ^/?(\.git|\.tx|SQL|bin|config|logs|temp|tests|program\/(include|lib|localization|steps)) - [F]
 # - deny access to some documentation files
 RewriteRule /?(README\.md|composer\.json-dist|composer\.json|package\.xml)$ - [F]
 </IfModule>

 <IfModule mod_deflate.c>
 SetOutputFilter DEFLATE
 </IfModule>

 <IfModule mod_expires.c>
 ExpiresActive On
 ExpiresDefault "access plus 1 month"
 </IfModule>

 FileETag MTime Size

 <IfModule mod_autoindex.c>
 Options -Indexes
 </ifModule>

 AllowOverride None
 Require all granted
</Directory>

<Directory /opt/roundcube/plugins/enigma/home>
 Options -FollowSymLinks
 AllowOverride None
 Require all denied
</Directory>

<Directory /opt/roundcube/config>
 Options -FollowSymLinks
 AllowOverride None
 Require all denied
</Directory>

<Directory /opt/roundcube/temp>
 Options -FollowSymLinks
 AllowOverride None
 Require all denied
</Directory>

<Directory /opt/roundcube/logs>
 Options -FollowSymLinks
 AllowOverride None
 Require all denied
</Directory>
EOF
   # needed this when installing on a vps
   sed -i "s/min_uid=100/min_uid=10/" /etc/suphp/suphp.conf
   sed -i "s/min_gid=100/min_gid=10/" /etc/suphp/suphp.conf

   a2enconf roundcube
   service apache2 reload

   read -p "Install ispconfig 3 plugins? (y/n) " ispconfig_install
   if [ $ispconfig_install = "y" ]; then
     cp /usr/local/ispconfig/interface/ssl/ispserver.crt /usr/local/share/ca-certificates/
     update-ca-certificates
     sed -i "s|;openssl.cafile=|openssl.cafile=/etc/ssl/certs/ca-certificates.crt|" /etc/php5/cgi/php.ini
     service apache2 restart
     package_install git
     echo "Please login to ispconfig 3 panel and create a remote user for username 'roundcube'"
     echo "and the complete address of your ispconfig 3 panel. (http://server:8080/ or https://server:8080/)"
     echo "note. setup will not work whitout these, ending up in maunal editting ispconfig3_account/config/config.inc.php"
     read -p "password: " soap_password
     read -p "ispconfig: " soap_port
     sed -i "s/soap_pass'] = 'roundcube';/soap_pass'] = '$soap_pass';/" ispconfig3_account/config/config.inc.php
     sed -i "s|soap_url'] = 'http://192.177.167.44:8080/remote/';|soap_url'] = '$soap_port/remote/';|"  ispconfig3_account/config/config.inc.php
     sed -i "/'zipdownload',/a 'jqueryui', 'ispconfig3_account', 'ispconfig3_autoreply', 'ispconfig3_pass', 'ispconfig3_spam', 'ispconfig3_fetchmail', 'ispconfig3_filter'" /opt/roundcube/config/config.inc.php
   fi
}
