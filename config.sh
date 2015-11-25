#!/bin/bash
#--------------------------------------------------#
# server-setup conf.                               #
# you dont need this, but it allows you to enable  #
# static values for server-setup.                  #
# -                                                #
# SET_CONFIG = 0  - default: 0 - 1 read config.    #
#--------------------------------------------------#

# Enable Config
SET_CONFIG=0

# this will override whiptail questions
# and Manual setup values.
Public_IP="192.168.0.2"
Hostname="server1.example.com"
Network_name="server1"
MySQL_Password="f1q2d3n4"

# whit this i need to rebuild InstallSources
# download your own custom sources.list
sources_link=""
sources_key=""
