#! /bin/bash
# * Menu.System.sh
#----------------------------------------------------------------------------------#
# Whiptail Menu system for ubuntu automated installer                              #
# this is the complete menu system.                                                #
# there proberly some other way todo this, but this will do for now.               #
# here we also collect most nessary info for the script to run                     #
# IP/FQDN/local name/MYSQL Password                                                #
# so basicly this is the base of the operation so to speek.                        #
#                                                                                  #
# please feel free to edit this script for your own needs, but i cant              #
# promise how the script will behaive after                                        #
# this has only been tested on ubuntu server 15.04                                 #
# Author: Nickless - admin@isengard.dk                                             #
#----------------------------------------------------------------------------------#

NORMAL=`echo "\033[m"`
MENU=`echo "\033[36m"` #Blue
NUMBER=`echo "\033[33m"` #yellow
FGRED=`echo "\033[41m"`
RED_TEXT=`echo "\033[31m"`
ENTER_LINE=`echo "\033[33m"`

EnableQuestions(){
    echo -e "${MENU} Ubuntu Server Automated installer ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU} this script will help you to setup you parfect server. ${NORMAL}"
    echo -e "${MENU} this setup is based howtoforge's TUT's on the Perfect server${NORMAL}"
    echo -e "${MENU} for Ubuntu Servers. as for now it only supports ubuntu 15.04 ${NORMAL}"
    echo -e "${MENU} but hope to support 14.05 & 15.10 in the future so please stay tune.${NORMAL}"
    echo -e "${MENU} for more info about this script see http://github.com/gimli/server-setup/${NORMAL}"
    echo -e "${MENU} please post any issuses and idea's on the page above..${NORMAL}"
    echo -e ""
    echo -e "${MENU} Your System: DISTRIB_DESCRIPTION ($DISTRIB_CODENAME) ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU}**${NUMBER} 1)${MENU} Allow Root SSH Access. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 2)${MENU} Install ISPConfig 3. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 3)${MENU} Show Extra's. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 4)${MENU} Check for updates. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 5)${MENU} view Script Config ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 6)${MENU} view system info. ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 7)${MENU} Help ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    read opt
}

option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

# First run creation.
source /etc/server-setup.conf
Collect_info() {
  MY_IP=$(hostname -i)
  if [ $SET_CONFIG = 0 ]; then
    echo -e "${MENU} Your config file needs to be set. so we need you to fill in the needed info. ${NORMAL}"
    echo -e "${MENU} We need to know the following, FQDN / network name / server ip / mysql root password ${NORMAL}"
    echo -e "${MENU} we have detected the following system values, Please edit them if u need. ${NORMAL}"
    echo -e "${MENU} also we need these values to install ISPConfig 3 correct.${NORMAL}"
    echo -e "${MENU} --------------------------------------------------------------------------------${NORMAL}"
    echo -e "${MENU} FQDN: $HOSTNAME - Network Name: $HOSTNAMESHORT ${NORMAL}"
    echo -e "${MENU} Public IP: $MY_IP - MySQL Password: xxxxxxxxxx ${NORMAL}"
    echo -e "${MENU} -------------------------------------------------------------------------------- ${NORMAL}"
    echo -e "${MENU} note. When you edit theese setting you will set them system-wide. ${NORMAL}"
    read -p " Do you want to edit current settings? (y/n) " edit
    if [ $edit = "y" ]; then
       read -p " FQDN Hostname: " HOSTNAMEFQDN
       read -p " Network Hostname: " HOSTNAMESHORT
       read -p " Server IP-Address: " serverIP
       read -p " MySQL Root Password: " mysql_pass
       sed -i "/SET_CONFIG=0/a mysql_pass='"${mysql_pass}"'" /etc/server-setup.conf
       sed -i "/SET_CONFIG=0/a serverIP='"${serverIP}"'" /etc/server-setup.conf
       sed -i "/SET_CONFIG=0/a HOSTNAMESHORT='"${HOSTNAMESHORT}"'" /etc/server-setup.conf
       sed -i "/SET_CONFIG=0/a HOSTNAMEFQDN='"${HOSTNAMEFQDN}"'" /etc/server-setup.conf
       sed -i "s/SET_CONFIG=0/SET_CONFIG=1/" /etc/server-setup.conf
       # we use this later but by calling config values for setting up hosts & hostname correct.
    fi
  fi
}

EnableExtras()
{
     subopt2=""
     while [ "$subopt2" != "x" ]
     do
         clear
         echo -e "${MENU}Ubuntu Server Autmated installer - Extra's${NORMAL}"
         echo -e "${MENU}note these script might be abit buggy. ${NORMAL}"
         echo -e "${MENU}*********************************************${NORMAL}"
         echo -e "${MENU}**${NUMBER} 1)${MENU} Setup OpenVPN / Havp / Privoxy${NORMAL}"
         echo -e "${MENU}**${NUMBER} 2)${MENU} Setup Munin / Monit Services${NORMAL}"
         echo -e "${MENU}**${NUMBER} 3)${MENU} Setup Reprepro APT repo${NORMAL}"
         echo -e "${MENU}**${NUMBER} 4)${MENU} Setup Gitlab Environment${NORMAL}"
         echo -e "${MENU}**${NUMBER} 5)${MENU} Setup Mumble VOIP server${NORMAL}"
         echo -e "${MENU}**${NUMBER} 6)${MENU} Setup VNC / XFCE Headless servers${NORMAL}"
         echo -e "${MENU}**${NUMBER} 7)${MENU} Setup UFW Firewall${NORMAL}"
         echo -e "${MENU}**${NUMBER} 8)${MENU} Setup Roundcube Webmail${NORMAL}"
         echo -e "${MENU}**${NUMBER} 9)${MENU} Setup Squirrelmail Webmail${NORMAL}"
         echo -e "${MENU}**${NUMBER} 10)${MENU} Setup UnrealIRCD / Anope Services${NORMAL}"
         echo -e "${MENU}---------------------------------------------${NORMAL}"
         echo -e "${MENU}**${NUMBER} x)${MENU} Return to main men${NORMAL}"
         echo -e "${MENU}**${NUMBER} e)${MENU} Exit server-setup${NORMAL}"
         echo -e "${MENU}*********************************************${NORMAL}"
         echo -e "${ENTER_LINE}Please enter a menu option and enter. ${NORMAL}"
         read subopt2
         case $subopt2 in
           1) clear;EnableOpenVPN;EnableHavp;EnableProxy;clear ;;
           2) clear;EnableMunin;EnableMonit;clear ;;
           3) clear;apt-get update | sh test2.sh "Updating sources";clear;;
           e) clear;exit 0 ;;
         esac
     done
}
