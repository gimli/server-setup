#!/bin/bash
#--------------------------------------------------#
# server-setup conf.                               #
# you dont need this, but it allows you to enable  #
# static values for server-setup.                  #
# -                                                #
# SET_CONFIG = 0  - default: 0 - 1 read config.    #
# HOSTNAMEFQDN = "server1.example.com"             #
# HOSTNAMESHORT = "server1"                        #
# serverIP = "pub.lic.ip.here"                     #
# mysql_pass = "rootMySQLPassword"                 #
#--------------------------------------------------#

# Enable Config
SET_CONFIG=0

# this will override whiptail questions
# and Manual setup values.
HOSTNAMEFQDN="server1.example.com"
HOSTNAMESHORT="server1"
serverIP="192.168.0.2"
mysql_pass="f8s8dkepfi192kmdq"

# whit this i need to rebuild InstallSources
# download your own custom sources.list
sources_link=""
sources_key=""
