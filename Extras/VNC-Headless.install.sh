#!/bin/bash
#--------------------------------------------------------------#
# this script will help you install VNC if your running a      #
# Head-less server this can be useful for running software     #
# like vmware and such. note. we're not gonna open any ports   #
# for VNC since VNC is easly hacked. so to connect to your     #
# server you need to create a ssh-tunnel.                      #
# - Ubuntu Server Automated Installer                          #
# - Author: Nickless - admin@isengard.dk                       #
# - Link:                                                      #
#--------------------------------------------------------------#

EnableVNCHeadless(){
   apt-get update
   apt-get -y install xfce4 xfce4-goodies tightvncserver
   vncserver
   vncserver -kill :1
   mv ~/.vnc/xstartup ~/.vnc/xstartup.bak
   cd ~/.vnc
   cat > xstartup <<EOF
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
   chmod +x ~/.vnc/xstartup

   # This is not a init.d script, but it will be placed in /usr/sbin
   cd /root/
   cat > vncserver <<EOF
#!/bin/sh
# Edit this to suit your needs
#
# author: nickless - admin@isengard.dk
# Copyrigth @ 2015
#
# Display = display port
# User = username
# Port = 5901
# options = Default vnc options
# syslog_check = 1 enable syslogging - 0 disable syslogging
#

DISPLAY=1
USER="root"
PORT=5901
OPTIONS="-geometry 1024x768 -depth 24 -pixelformat RGB888 -nolisten tcp -localhost"
SYSLOG_CHECK=0

####################################
# # # Dont edit anything below # # #
####################################
PATH="$PATH:/usr/bin/"
PID=$HOSTNAME":"$DISPLAY".pid"
PATH_VNC="/"$USER"/.vnc/"
. /lib/lsb/init-functions

case "$1" in
status)
 if [ -f $PATH_VNC$PID ]
   then
        log_action_begin_msg "VNC Server is Currently running on $HOSTNAME:$PORT"
        log_action_begin_msg "Login: $HOSTNAME:$PORT - Password: ***********"

        # Enable syslog
        if [ $SYSLOG_CHECK = 1 ]
         then
           logger "VNC Server is currently running on $HOSTNAME:$PORT"
           logger "Login: $HOSTNAME:$PORT - Password: ***********"
        fi
        exit 0
   else
        log_action_begin_msg "VNC Server is Currently Down."

        # syslog
        if [ $SYSLOG_CHECK = 1 ]
         then
            logger "VNC Server is Currently Down."
         fi
        exit 0
 fi
;;

start)
  if [ -f $PATH_VNC$PID ]
    then
      log_action_begin_msg "VNC Server is already running, try ./vnc-server restart (this will force a restart)"
      log_action_begin_msg "VNC Server: "$HOSTNAME":"$PORT

      # Enable syslog
      if [ $SYSLOG_CHECK = 1 ]
       then
         logger "VNC Server is already running, try ./vnc-server restart (this will force a restart)"
         logger "VNC Server: $HOSTNAME:$PORT"
      fi
      exit 0
  fi
  log_action_begin_msg "starting vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"

  # Enable syslog
  if [ $SYSLOG_CHECK = 1 ]
    then
        logger "starting vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  fi
  /usr/bin/vncserver $OPTIONS
;;

restart)
  log_action_begin_msg "restarting vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  /usr/bin/vncserver -kill :${DISPLAY}
  if [ $SYSLOG_CHECK = 1 ]
    then
        logger "restarting vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  fi
  log_action_begin_msg "starting vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  /usr/bin/vncserver $OPTIONS
;;

stop)
  log_action_begin_msg "Stopping vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  if [ $SYSLOG_CHECK = 1 ]
    then
        logger "stopping vncserver for user '${USER}' on ${HOSTNAME}:${DISPLAY}"
  fi
  /usr/bin/vncserver -kill :${DISPLAY}
;;

esac
exit 0
EOF

   # fix rights & fire-up VNC server
   # ths reason we do vncserver in root
   # is that we dont want our VNC server running when not used
   # this is usedfuld if running vmware software or stuff like that
   # you will need to create a ssh tunnel via localhost to gain access to remote system
   # you can do so whit: ssh -L 5901:127.0.0.1:5901 -N -f -l username server_ip_address
   # or you can do ufw allow 5901/tcp but its a fairly riski move.
   chmod +x /root/vncserver
   /root/vncserver start
   /root/vncserver status
   vncserver
   echo "Server info: $serverIP:5901 and the password you created early in the process."
}
