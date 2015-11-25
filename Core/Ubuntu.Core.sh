#!/bin/bash
#
# this is the main engine of our script
# more info will follow..
#
#

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
   package_install hostname
   echo $HOSTNAMEFQDN > /etc/hostname
   /etc/init.d/hostname.sh restart
   sed -i "/127.0.1.1/a $serverIP $HOSTNAMEFQDN  $HOSTNAMESHORT" /etc/hosts
   sed -i "/127.0.1.1/d" /etc/hosts
}

AllowRootSSH(){
   # this needy little script will allow root access
   package_install ssh openssh-server
   sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config
   service ssh restart 
   service sshd restart
   passwd root
}

InstallSources(){
    # this my own privat repo this contains server-setup always latest version
    # along whit afew other packages like fixed version of libavahi-core7 to avoid syslog spamming.
    wget -O - -q http://apt.isengard.xyz/apt.isengard.xyz.gpg.key | apt-key add -
    if [ -f /etc/apt/sources.list.d/isengard.list ]; then
       echo "Sources is already installed.."
    else
       echo "deb http://apt.isengard.xyz/debian/ vivid main" > /etc/apt/sources.list.d/isengard.list
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
    echo "Updating sources.."
    package_update
    echo "Upgrading system.."
    package_upgrade

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

check_webserver(){
   if check_package apache2 = 1; then
     echo "apache installed"
   fi
}

package_clean() {
        echo "Cleaning packages, please standby."
	apt-get -qq clean
}

package_clean_list() {
	echo -n > /var/lib/apt/extended_states
}

package_install() {
        echo "Installing $*, please standby."
	apt-get -q -y install "$*"
}

package_uninstall() {
        echo "Uninstalling $*, please standby."
	apt-get -q -y purge "$*"
}

package_update() {
        echo "Updating sources, please standby."
	apt-get -qq update
}

package_upgrade() {
        echo "Upgrading system, please standby."
	apt-get -qq -y upgrade
}

check_package() {
   if dpkg -l $1 2> /dev/null | egrep -q ^ii; then
     check_packages=1
   else
     check_packages=0
  fi
}

check_repository() {
	grep -iq $1 /etc/apt/sources.list || [ -f /etc/apt/sources.list.d/$1.list ]
}
