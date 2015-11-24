#!/bin/bash

if [ $ARGS = "--help" ]; then
  echo "availble commands.. --run-upgrade does as it says, upgrading script."
  echo " * --help"
  echo " * --run-upgrade"
  echo " * --run-uninstall"
  exit 0
fi

if [ $ARGS = "--run-upgrade" ]; then
  echo "Updating server-setup script, please hold on.."
  if [ -f /opt/server-setup ]; then
    echo "updating dir: /opt/server-setup"
    cd /opt/server-setup
  else
    echo "updating dir: ~/server-setup"
    cd ~/server-setup
  fi
  git pull
  exit 0
fi

if [ $ARGS = "--run-uninstall" ]; then
   read -p "Are you sure you want to uninstall server-setup? (y/N) " uninstall
   if [ $uninstall = "y" ]; then
      apt-get purge server-setup
      rm -rf /opt/server-setup
      rm /usr/sbin/server-setup
      cd;clear
      echo "Script uninstalled! We Hope you enjoyed using the script."
      exit 0
   fi
   exit 0
fi
