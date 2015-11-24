#!/bin/bash
#-------------------------------------------#
# this script will help you install mumble  #
# server emvironment on your server.        #
# - Ubuntu Server Automated Installer       #
# - Author: Nickless - admin@isengard.dk    #
# - Link: https://www.howtoforge.com/tutorial/how-to-install-mumble-voip-server-on-ubuntu-15-04-vivid-vervet/
#-------------------------------------------#

EnableMumble(){
  add-apt-repository ppa:mumble/release
  apt-get update
  apt-get -yqq install mumble-server
  dpkg-reconfigure mumble-server

  sed -i "s/#autobanAttempts = 10/autobanAttempts = 10/" /etc/mumble-server.ini
  sed -i "s/#autobanTimeframe = 120/autobanTimeframe = 120/" /etc/mumble-server.ini
  sed -i "s/#autobanTime = 300/autobanTime = 300/" /etc/mumble-server.ini
  sed -i "s/#allowhtml=true/allowhtml=true/" /etc/mumble-server.ini

  service mumble-server start
  service mumble-server restart
}
