#!/bin/bash
#
# this is the main engine of our script
# more info will follow..
#
#

# CheckRoot(){
#
# }

CheckInternet(){

   # Let's check for internet lets start by
   # Connecting whit google.com
   if ping -c3 google.com > /dev/null;
    then
      echo -e "[${green}DONE${NC}]\n"
   else
      echo -e "[${red}failed${NC}]\n"
      exit 1
   fi
}

CheckRoot(){

   # Check if root is present and die if not.
   if [ $(id -u) != "0" ]; then
     echo -n "Error: You must be root to run this script, please run sudo bash run_me.sh. "
     echo -e "[${red}failed${NC}]\n"
     exit 1
   fi
}

SetNewHostname(){
   # this way it will ensure ppl. whit dynamic ip's
   # to get a correct setup of hostname/ip
   # this will delete old/create new hostname file.
   # i need to find a new simple way todo so
   rm /etc/hostname
   touch /etc/hostname
   echo $HOSTNAMEFQDN >> /etc/hostname
   sed -i "s|127.0.1.1|#127.0.1.1|" /etc/hosts
   sed -i "/#127.0.1.1/ a $serverIP $HOSTNAMEFQDN $HOSTNAMESHORT" /etc/hosts
   /etc/init.d/hostname.sh restart
}

AllowRootSSH(){
   # this needy little script will allow root access
   sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config
   service ssh restart 
   service sshd restart
   passwd root
}

InstallSources(){
   ubuntu_sources="http://dl.isengard.xyz/secret_download/conf/sources.list"
   mv /etc/apt/sources.list /etc/apt/sources.list.bak
   wget $ubuntu_sources > /dev/null 2>&1
   mv sources.list /etc/apt/
   if [ -f /etc/apt/sources.list ];
     then
       echo -e "[DONE]"
   else
       # Restore old sources.list & continue script (failsafe)
       # just in case we are unable to download new sources
       # it should however be fine since this script only is
       # for ubuntu server 15.04..
       mv /etc/apt/sources.list.bak /etc/apt/sources.list
   fi
}

AptUpgrade(){
  if [ -f reboot.tmp ];
    then
    # we can remove this again sinces system should
    # already be updatet since this file has been
    # generated.
    rm reboot.tmp
  else
    apt-get -yqq update
    apt-get -yqq dist-upgrade

    # generate reboot.tmp to ensure update/dist-upgrade
    # goes as planed before installing anything new
    # this mainly goes for ispconfig reboot will
    # also update current hostname according to our setup
    touch reboot.tmp
    echo 1 >> reboot.tmp
    read -p "reboot system? (y/n) " reboot
    if [ $reboot = "y" ];
     then
        echo "please re-run this script after rebooting"
        reboot
    else
        # Delete reboot.tmp on user request
        # user will restart manual on a later time
        rm reboot.tmp
    fi
  fi
}

package_clean() {
	apt-get clean
}

package_clean_list() {
	echo -n > /var/lib/apt/extended_states
}

package_install() {
	apt-get -q -y install "$*"
}

package_uninstall() {
	apt-get -q -y purge "$*"
}

package_update() {
	apt-get update
}

package_upgrade() {
	apt-get -q -y upgrade
}

check_package() {
	dpkg -l $1 2> /dev/null | egrep -q ^ii
}

check_repository() {
	grep -iq $1 /etc/apt/sources.list || [ -f /etc/apt/sources.list.d/$1.list ]
}
