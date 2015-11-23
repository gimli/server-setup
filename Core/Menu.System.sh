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

# Let's collect our ip-address
# also this seems to be this best way to detect our ip-address
MY_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`


# Define background title for installer
# We only need this defined once thats why
# we keep here..
# also script users dont need to change this.
back_title="Ubuntu automated setup"
welcome_title="Welcome to installer"
window_title="installer"

#----------------------------------------------------------------------------------#
# Engine - Please do not touch below                                               #
# only do so if you know wgat todo                                                 #
#----------------------------------------------------------------------------------#

EnableQuestions() {
whiptail --backtitle "$back_title" --title "Welcome to installer" --yesno --defaultno "Welcome to Ubuntu Server automated installer. This will guide you on your way ;) Do you want to Continue ?" 8 78
exitstatus=$?
if [ $exitstatus = 0 ]; then
    status="0"
    while [ "$status" -eq 0 ]
    do

       # Lets make sure we only collect info once while script is running
       # since its working whit loop
       if [ ! $collect_info ]; then

        # Define serverIP / this will detect and setup your host ip
        serverIP=$(whiptail --inputbox "What is your ip-address?" 8 78 $MY_IP --backtitle "$back_title" --title "Detect Public IP" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
          serverIP=$MY_IP
        else
          serverIP=$server_IP
        fi

        # Define FQDN / Setup FQDN hostname
        HOSTNAMEFQDN=$(whiptail --inputbox "What is your FQDN Hostname?" 8 78 $HOSTNAME --backtitle "$back_title" --title "Detect Hostname" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
           HOSTNAMEFQDN=$HOSTNAME
        else
           HOSTNAMEFQDN=$HOSTNAMEFQDN
        fi

        # Define local network name
        # also we need to find local network name
        # in /etc/hostname / this will split FQDN "."
        # to locate our local network name.
        hostnameshort=`cat /etc/hostname`
        IFS='.' read -a short <<< "$hostnameshort"
        HOSTNAMESHORT=$(whiptail --inputbox "What is your local network name?" 8 78 ${short[0]} --backtitle "$back_title" --title "Detect local network name" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
           HOSTNAMESHORT=$hostnameshort
        else
           HOSTNAMESHORT=$HOSTNAMESHORT
        fi

        # Check if Mysql-Server is running and if not then collect mysql-password
        # note the script will continue whitout password this function will only be
        # called upon first run of this script..
        # also we dont store anything whitin this script, meaning that your password will
        # reset whitin the script upon quit
        if [ ! /var/run/mysqld/mysqld.pid ]; then
         PASSWORD=$(whiptail --passwordbox "please enter your mysql root password" 8 78 --title "MySQL Root Password" 3>&1 1>&2 2>&3)
         exitstatus=$?
         if [ $exitstatus = 0 ]; then
            mysql_pass=$PASSWORD
         else
            mysql_pass=""
          fi
        else
            # MySQL-Server is already running, we dont need password unless asked for.
            # this function is really not needed and will be removed later on.
            mysql_pid=`cat /var/run/mysqld/mysqld.pid`
            whiptail --backtitle "$back_title" --title "Installer" --msgbox "MySQL Server is running (pid $mysql_pid.), The script will continue but may ask for your mysql root password later if needed." 8 78
        fi

        # Only collect information once while script is running
        collect_info=1
       fi

        # Main Engine - Complete Menu System for the hole script
        # i tried the best to keep it all in a loop * return all submenu to main menu once done.
        # Only exit uppon unknowen command or cancel/Exit
        # so fare all i need is gauge for installers i hope ill figure somthing out soon otherwise 
        # ill proceed whitout. 
        # . /etc/lsb-release
        choice=$(whiptail --backtitle "$back_title" --title "Main Menu" --menu "This Guide will help you install the Perfect Server - Ubuntu Server $DISTRIB_RELEASE on your server. In Extra's you'll find afew script that will help you install stuff like OpenVPN/Gitlab and so on.. also if you wanner be sure you got the rigth account select allow root ssh and ssh root@$MY_IP - Thank you for using this script :)" 22 80 5 \
        "1" "Allow Root SSH." \
        "2" "Setup ISPConfig 3." \
        "3" "Package Installer." \
        "4" "Extra's" \
        "5" "Help" \
        "6" "Exit installer" 3>&2 2>&1 1>&3)

        # Let clean $choise before choosing function
        option=$(echo $choice | tr '[:upper:]' '[:lower:]' | sed 's/ //g')
        case "${option}" in
            1)
                # Enable Root SSH access.
                # this script will allow you to
                # gain root access via SSH
                # by editting /etc/ssh/sshd_config and allow root password
                # restart ssh/sshd & setup password for root. this should work outta the box
                AllowRootSSH
            ;;
            2)
               # ISPConfig 3 Setup Start.
               # Check for previus ISPConfig install
               CheckISPConfig

               # Download and install deps. for ISPConfig 3
               SetupBasic
               DisableApparmor
               EnableApache
               EnableMySQL
               EnableDovecot
               EnableVirus
               EnableMailman
               EnablePureFTPD
               EnableQuota
               EnableBind
               EnableStats
               EnableJailkit
               EnableFail2ban
               EnableFail2BanRulesDovecot
               EnableISPConfig3

               # Install Squirrelmail Webmail
               if (whiptail --backtitle "$back_title" --title "Installer" --yesno "Do you wish to install Squirrelmail Webmail?" 8 78); then
                  EnableSquirrelmail
               fi
               # Install Roundcube Webmail
               if (whiptail --backtitle "$back_title" --title "Installer" --yesno "Do you wish to install Roundcube Webmail?" 8 78); then
                  EnableRoundcube
               fi
               # Install ISPConfig 3 ISPC_clean theme
               if (whiptail --backtitle "$back_title" --title "Installer" --yesno "Do you wish to install ISPC_Clean theme for ISPConfig 3?" 8 78); then
                  EnableISPC_Clean
               fi
               # ISPConfig 3 Setup End
            ;;
            3)
            ;;
            4)
               # This Creates a submenu for extra's
               # in the end, this will return to main menu when done
               # unless script is toll othrwise at the end of commands
               choice=$(whiptail --backtitle "Ubuntu Automated Installer" --title "Extra's Menu" --menu "Welcome to Extra's Menu. Here you'll find afew script to help you out on building the perfect server for you. no need to explain alot the menu's pretty much say it! ;)" 22 80 5 \
                  1 "Setup OpenVPN / Havp / Privoxy"\
                  2 "Setup Munin & Monit Services"\
                  3 "Setup Gitlab Enviroment"\
                  4 "Setup Mumble VOIP Server"\
                  5 "Setup APT Repostorie"\
                  6 "Setup VNC Headless Server"\
                  7 "Setup UFW Firewall"\
                  8 "Setup UnrealIRCD & Anope Services"\
                  9 "Setup Roundcube Webmail"\
                  10 "Setup Squirrelmail Webmail"\
                  11 "Return to main menu" 3>&1 1>&2 2>&3)

               # Once again we clean out whiptail out-put.
               option=$(echo $choice | tr '[:upper:]' '[:lower:]' | sed 's/ //g')
               case "${option}" in
               1)   # Setup OpenVPN / Havp / Privoxy
                    EnableOpenVPN
                    EnableHavp
                    EnablePrivoxy
                    # Setup OpenVPN END
               ;;
               2)
                    # Setup Munin & Monit
                    EnableMunin
                    EnableMonit
                    whiptail --backtitle "$back_title" --title "Installer" --msgbox "Install Finished. Monit/Munin is now available on you host. http://$HOSTNAMEFQDN/monit & http://$HOSTNAMEFQDN:2812. ill return to main menu" 8 78
                    # Setup Munin/Monit END
               ;;
               *)
                    # Return to Main menu
                    status=0
               ;;
               esac
               # Change Exit status for script
               exitstatus1=$status #1
               # End Submenu for Extra´s #
            ;;
            5)
               # Help and Infomation about author & Script
               whiptail --title "Help" --msgbox "Help will get here soon.." 8 78
            ;;
            *)
                # Exit Script.
                whiptail --backtitle "ubuntu automated installer" --title "Installer" --msgbox "You have finished." 8 78
                status=1
                exit
            ;;
        esac
       # change exit state 
       exitstatus1=$status1
    done
else
    # Close script before started.
    whiptail --backtitle "ubuntu automated installer" --title "Installer" --msgbox "You have choose to Exit installer. Script will exit." 8 78
    exit
fi
}
