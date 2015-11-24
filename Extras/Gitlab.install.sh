#!/bin/bash
#------------------------------------------------------------------#
# this script will help you setup a gitlab environment on your     #
# server. also to allow gitlab install run on a host whit multiply #
# sites. note this works in ubuntu 15.04.                          #
# i will add more info later..                                     #
# - Ubuntu Server Automated Installer                              #
# - Author: Nickless - admin@isenard.dk                            #
# - Link:                                                          #
#------------------------------------------------------------------#

EnableGitlab(){

  # Download & run default config
  apt-get -yqq install curl openssh-server ca-certificates postfix debian-archive-keyring apt-transport-https
  #echo "deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/ trusty main" >> /etc/apt/sources.list.d/gitlab_gitlab-ce.list
  apt-get update
  apt-get -y install gitlab-ce

  # Set afew config values
  read -p "Please enter the domain your gitlab install should be installed under? " domain_name

  # Needed to make apache2/nginx behave right
  # on the same server.
  sed -i "s/        listen       80;/        listen       83;/" /opt/gitlab/embedded/conf/nginx.conf
  sed -i "s/        server_name  localhost;/        server_name  gitlab.$domain_name;/" /opt/gitlab/embedded/conf/nginx.conf
  sed -i "s/        listen       80;/        listen       83;/" /opt/gitlab/embedded/conf/nginx.conf.default
  sed -i "s/        server_name  localhost;/        server_name  gitlab.$domain_name;/" /opt/gitlab/embedded/conf/nginx.conf.default


  # Setup Apache2.4 Vhost
  cd /etc/apache2/conf-enabled/
  cat > gitlab.conf << EOF
#This configuration has been tested on GitLab 8.0.0
#Note this config assumes unicorn is listening on default port 8080 and gitlab-git-http-server is listening on port 8181.
#To allow gitlab-git-http-server to listen on port 8181, edit or create /etc/default/gitlab and change or add the following:
#gitlab_git_http_server_options="-listenUmask 0 -listenNetwork tcp -listenAddr localhost:8181 -authBackend http://127.0.0.1:8080"

#Module dependencies
#  mod_rewrite
#  mod_proxy
#  mod_proxy_http
<VirtualHost *:80>
  ServerName gitlab.$domain_name
  ServerSignature Off

  ProxyPreserveHost On

  # Ensure that encoded slashes are not decoded but left in their encoded state.
  # http://doc.gitlab.com/ce/api/projects.html#get-single-project
  AllowEncodedSlashes NoDecode

  <Location />
    # New authorization commands for apache 2.4 and up
    # http://httpd.apache.org/docs/2.4/upgrading.html#access
    Require all granted

    #Allow forwarding to gitlab-git-http-server
    ProxyPassReverse http://127.0.0.1:8181
    #Allow forwarding to GitLab Rails app (Unicorn)

    ProxyPassReverse http://127.0.0.1:8080
    ProxyPassReverse http://gitlab.isengard.dk/
  </Location>

  #apache equivalent of nginx try files
  # http://serverfault.com/questions/290784/what-is-apaches-equivalent-of-nginxs-try-files
  # http://stackoverflow.com/questions/10954516/apache2-proxypass-for-rails-app-gitlab
  RewriteEngine on

  #Forward requests ending with .git to gitlab-git-http-server
  RewriteCond %{REQUEST_URI} [-\/\w\.]+\.git\/
  RewriteRule .* http://127.0.0.1:8181%{REQUEST_URI} [P,QSA]

  #Forward any other requests to GitLab Rails app (Unicorn)
  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f [OR]
  RewriteCond %{REQUEST_URI} ^/uploads
  RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA,NE]

  # needed for downloading attachments
  DocumentRoot /opt/gitlab/embedded/service/gitlab-rails/public

  #Set up apache error documents, if back end goes down (i.e. 503 error) then a maintenance/deploy page is thrown up.
  ErrorDocument 404 /404.html
  ErrorDocument 422 /422.html
  ErrorDocument 500 /500.html
  ErrorDocument 503 /deploy.html

  LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b" common_forwarded
  ErrorLog  /var/log/apache2/gitlab.isengard.dk_error.log
  CustomLog /var/log/apache2/gitlab.isengard.dk_forwarded.log common_forwarded
  CustomLog /var/log/apache2/gitlab.isengard.dk_access.log combined env=!dontlog
  CustomLog /var/log/apache2/gitlab.isengard.dk.log combined

</VirtualHost>
EOF

  # Create a fix to make sure apache2 is up and running
  # before Nginx otherwise it will fail to bring apache2 up
  # and you will only be able to access gitlab.domain.com
  # but whit this you will be able to run multiply site's
  # on the same server.
  cd /root/
  cat > fix_gitlab.sh <<EOF
#
# Simple restart script for cron
# This script simply restart apache2
# and log to syslog if apache2 fails to start
# script tested on Ubuntu Server 15.04
#
# Author: admin@isengard.dk
#

PID_FILE="/var/run/apache2/apache2.pid"
. /lib/lsb/init-functions
SYSLOG_CHECK=0

if [ -f $PID_FILE ]
  then
    if [ $SYSLOG_CHECK = 1 ]
      then
          logger "Apache2 is currently running along side gitlab-ctl nginx config."
          logger "No need to restart.."
    fi
   log_action_begin_msg "Apache2 is currently running along side gitlab-ctl nginx config"
   log_action_begin_msg "No need to restart"
   exit 0
  else
      if [ $SYSLOG_CHECK = 1 ]
        then
           logger "Restarting Apache2.."
           logger "Restarting Nginx.. (gitlab-ctl setup)"
      fi
      /etc/init.d/apache2 stop
      gitlab-ctl stop nginx
      /etc/init.d/apache2 start
      gitlab-ctl start nginx
      if [ $SYSLOG_CHECK = 1 ]
       then
         logger "Services Apache2/Nginx restarted.."
      fi
      log_action_begin_msg "Services Apache2/Nginx restarted"
      if [ -f $PID_FILE ]
        then
          if [ $SYSLOG_CHECK = 1 ]
             then
                 logger "Services Apache2/Nginx restarted"
          fi
          exit 0
        else
          log_action_begin_msg "apache2 failed to starts please see /var/log/apache2/error.log"
          if [ $SYSLOG_CHECK = 1 ]
            then
                 logger " apache2 failed to start please see /var/log/apache2/error.log"
          fi
      fi
fi
exit 0
EOF

  # Set right on restart script
  chmod +x /root/fix_gitlab.sh

  # Restart Gitlab-ce
  gitlab-ctl reconfigure
  gitlab-ctl restart
  sh /root/fix_gitlab.sh # its a simple restart script for apache2 & nginx install by gitlab, but we need to start apache2 before nginx.
}
