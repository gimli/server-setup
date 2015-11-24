#!/bin/bash
#------------------------------------------------------------------#
# This Script will help you setup UFW firewall up on your ubuntu   #
# Server. later i will add a gui for the firewall allowing newbies #
# to easly install and setup firewall on the system.               #
# - Ubuntu Server Automated Installer.                             #
# - Author: Nickless - admin@isengard.dk                           #
# - Link:                                                          #
#------------------------------------------------------------------#

EnableUFW(){
   package_update
   package_upgrade
   package_install ufw
   read -p "Enable default ISPConfig 3 ports? (y/n) " default_ports
   read -p "Please enter ISPConfig 3 port? [8080] " ispc_port

   # Enable default ISPConfig 3 port
   if [ ! $ispc_port ]; then
      ispc_port=8080
   fi

   PORTS=("21/tcp" "22/tcp" "23/tcp" "25/tcp" "53/tcp" "53/udp" "80/tcp" "$ispc_port/tcp" "110/tcp" "143/tcp" "443/tcp" "456/tcp" "587/tcp" "993/tcp" "995/tcp" "3306/tcp" "8081/tcp")
   for i in ${PORTS[@]} 
   do
      ufw allow $i
   done

   read -p "Enable OpenVPN default Port? (y/n) " openVPN
   if [ $openVPN = "y" ]; then
     ufw allow 1194/tcp
   fi

   read -p "Enable Munin Default port? (y/n) " munin
   if [ $munin = "y" ]; then
     ufw allow 2812/tcp
   fi

   read -p "Enable Pure-Ftpd passive ports? (y/n) " pureftp
   if [ $pureftp = "y" ]; then
     ufw allow 40110:40210/tcp
   fi

   read -p "Enable IRCD default port? (y/n) " ircd
   if [ $ircd = "y" ]; then
     ufw allow 6667/tcp
   fi
   echo "Enabling firewall.."
   ufw enable
}
