#!/bin/bash

case $ARGS in
  --help)
       echo "Help. Here a list of the availble commands."
       echo " * --help "
       echo " * --run-upgrade "
       echo " * --run-uninstall "
       exit 0
  ;;
  --run-upgrade)
       echo "Updating script..."
       cd /opt/server-setup
       git add .
       git commit -a -m 'pull it all together, and upgrade.'
       git pull
       exit 0
  ;;
  --run-uninstall)
      read -p "Are you sure ? (y/n) " do_so
      if [ $do_so = "y" ]; then
         echo "Uninstalling server-setup, please standby."
         apt-get purge server-setup
         cd ~/
         clear
         exit 0
      fi
      exit 0
  ;;
  #*)
  #    echo "Sorry i didnt understand your command, please try --help for more info."
  #    exit 0
  #;;
esac
