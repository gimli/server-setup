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

  # fixed version, avoid avahi-daemon spamming syslog.
  wget http://dl.isengard.xyz/debian/pool/main/a/avahi/libavahi-core7_0.6.31-4ubuntu4_amd64.deb
  dpkg -i libavahi-core7_0.6.31-4ubuntu4_amd64.deb

  service mumble-server start
  service mumble-server restart
}
