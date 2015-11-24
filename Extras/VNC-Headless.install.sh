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
   package_update
   package_upgrade
   packages=("xfce4" "xfce4-goodies" "tightvncserver")
   for i in "${packages[@]}"
    do
      package_install $i
   done
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
   vncserver
   echo "Server info: $serverIP:5901 and the password you created early in the process."
}
