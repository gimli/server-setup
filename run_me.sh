#!/bin/bash
source Core/Ubuntu.Core.sh
source ISPConfig/ISPConfig.install.15.04.sh
source Extras/OpenVPN.install.sh
source Extras/MonitMunin.install.sh

HOSTNAMEFQDN="ubuntu.isengard.xyz"
HOSTNAMESHORT="ubuntu"
serverIP="209.126.70.243"
mysql_pass="bjo10ern21"

#CheckISPConfig
#SetNewHostname
#AllowRootSSH
#AptUpgrade
#InstallSources
#----------------------#
# ISPConfig 3          #
#----------------------#
#SetupBasic
#DisableApparmor
#EnableMYSQL
#EnableDovecot
#EnableVirus
#EnableApache
#EnableMailman
#EnablePureFTPD
#EnableQuota
#EnableBind
#EnableStats
#EnableJailkit
#EnableFail2ban
#EnableFail2BanRulesDovecot
#EnableISPConfig3
#EnableISPC_Clean
#----------------------#
# ISPConfig 3 end      #
# Extras               #
#----------------------#
#EnableOpenVPN
#EnableHavp
#EnableProxy
#EnableMonit
#EnableMunin
