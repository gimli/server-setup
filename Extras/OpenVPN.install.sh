#!/bin/bash
#-------------------------------------------------------------------#
# this script will help you install & setup OpenVPN / Havp / Privoxy#
# in this process we will install openvpn set it up for public use  #
# Create server/client certs, setup client.ovpn relocate ovpn into  #
# /root/ after the we will setup havp anti-virus & Privoxy as our   #
# transparent proxy server for vpn users.                           #
# - Ubuntu Server Automated Installer                               #
# - Author: Nickless - admin@isengard.dk                            #
# - Link:                                                           #
#-------------------------------------------------------------------#

EnableOpenVPN() {

  apt-get update
  apt-get -y install openvpn easy-rsa

  # this is the way to go, were cheating abit and select preconfigurated server.conf
  # gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
  # sed -i "s/dh dh1024.pem/dh dh2048.pem/" /etc/openvpn/server.conf
  # sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf
  # sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 8.8.8.8"/' /etc/openvpn/server.conf
  # sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 8.8.4.4"/' /etc/openvpn/server.conf
  # sed -i 's/;user noboby/user nobody/' /etc/openvpn/server.conf
  # sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf
  cd /etc/openvpn/
  cat > server.conf <<EOF
local $serverIP
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret
dh dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-config-dir ccd
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "register-dns"
push "block-ipv6"
sndbuf 0
rcvbuf 0
client-to-client
duplicate-cn
keepalive 10 120
comp-lzo
max-clients 100
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append  /var/log/openvpn.log
verb 3
EOF

  # Enable IP4 forwarding
  echo 1 > /proc/sys/net/ipv4/ip_forward
  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl -p

  # Enable UFW
  # apt-get install ufw
  # ufw allow ssh
  ufw allow 1194/udp
  sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
  mv /etc/ufw/before.rules /etc/ufw/before.rules.back
  echo "Please enter your public network interface name here."
  read -p "Interface: " default_interface
  cd /etc/ufw
  cat > before.rules <<EOF
#
# rules.before
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
#

# START OPENVPN RULES
# NAT table rules
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# transparent proxy
-A PREROUTING -i tun+ -p tcp --dport 80 -j REDIRECT --to-port 8082
# Allow traffic from OpenVPN client to em1
-A POSTROUTING -s 10.8.0.0/8 -o $default_interface -j MASQUERADE
COMMIT
# END OPENVPN RULES

# Don't delete these required lines, otherwise there will be errors
*filter
:ufw-before-input - [0:0]
:ufw-before-output - [0:0]
:ufw-before-forward - [0:0]
:ufw-not-local - [0:0]
# End required lines


# allow all on loopback
-A ufw-before-input -i lo -j ACCEPT
-A ufw-before-output -o lo -j ACCEPT

# quickly process packets for which we already have a connection
-A ufw-before-input -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-output -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# drop INVALID packets (logs these in loglevel medium and higher)
-A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
-A ufw-before-input -m conntrack --ctstate INVALID -j DROP

# ok icmp codes for INPUT
-A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-input -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT

# ok icmp code for FORWARD
-A ufw-before-forward -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT

# allow dhcp client to work
-A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT

#
# ufw-not-local
#
-A ufw-before-input -j ufw-not-local

# if LOCAL, RETURN
-A ufw-not-local -m addrtype --dst-type LOCAL -j RETURN

# if MULTICAST, RETURN
-A ufw-not-local -m addrtype --dst-type MULTICAST -j RETURN

# if BROADCAST, RETURN
-A ufw-not-local -m addrtype --dst-type BROADCAST -j RETURN

# all other non-local packets are dropped
-A ufw-not-local -m limit --limit 3/min --limit-burst 10 -j ufw-logging-deny
-A ufw-not-local -j DROP

# allow MULTICAST mDNS for service discovery (be sure the MULTICAST line above
# is uncommented)
-A ufw-before-input -p udp -d 224.0.0.251 --dport 5353 -j ACCEPT

# allow MULTICAST UPnP for service discovery (be sure the MULTICAST line above
# is uncommented)
-A ufw-before-input -p udp -d 239.255.255.250 --dport 1900 -j ACCEPT

# allow bridge networking
# -I FORWARD -m physdev –physdev-is-bridged -j ACCEPT

-A INPUT -m state --state INVALID -j DROP

# don't delete the 'COMMIT' line or these rules won't be processed
COMMIT
EOF

   # Setup certs & keys
   cd /etc/openvpn
   cp -r /usr/share/easy-rsa/ /etc/openvpn
   mkdir /etc/openvpn/easy-rsa/keys
   openssl dhparam -out /etc/openvpn/dh2048.pem 2048
   cd /etc/openvpn/easy-rsa/
   . ./vars
   ./clean-all
   ./build-ca
   ./build-key-server server
   cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
   service openvpn start
   service openvpn status

   # Create client key & config
   ./build-key your_OpenVPN_key
   cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/remote my-server-1 1194/remote $serverIP 1194/" /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/;user nobody/user nobody/" /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/;group nogroup/group nogroup/" /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/ca ca.crt/;ca ca.crt/" /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/cert client.crt/;cert client.crt/" /etc/openvpn/easy-rsa/keys/client.ovpn
   sed -i "s/key client.key/;key client.key/" /etc/openvpn/easy-rsa/keys/client.ovpn

   # Added newly created certs to .ovpn
   echo '<ca>' >> /etc/openvpn/easy-rsa/keys/client.ovpn
   cat /etc/openvpn/ca.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
   echo '</ca>' >> /etc/openvpn/easy-rsa/keys/client.ovpn

   echo '<cert>' >> /etc/openvpn/easy-rsa/keys/client.ovpn
   cat /etc/openvpn/easy-rsa/keys/your_OpenVPN_key.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
   echo '</cert>' >> /etc/openvpn/easy-rsa/keys/client.ovpn

   echo '<key>' >> /etc/openvpn/easy-rsa/keys/client.ovpn
   cat /etc/openvpn/easy-rsa/keys/your_OpenVPN_key.key >> /etc/openvpn/easy-rsa/keys/client.ovpn
   echo '</key>' >> /etc/openvpn/easy-rsa/keys/client.ovpn

   # Moved newly created OpenVPN Access key, simply load AccessVPN.ovpn and your
   # VPN Client and your good to go.
   cp -r /etc/openvpn/easy-rsa/keys/client.ovpn /root/AccessVPN.ovpn

}

EnableHavp() {
   apt-get -y install havp
   sed -i "s/ENABLECLAMLIB false/ENABLECLAMLIB true/" /etc/havp/havp.config
   sed -i "s/RANGE false/RANGE true/" /etc/havp/havp.config
   sed -i "s/# SCANIMAGES true/SCANIMAGES false/" /etc/havp/havp.config
   sed -i "s/# SKIPMIME image/SKIPMIME image/" /etc/havp/havp.config
   sed -i "s/# LOG_OKS true/LOG_OKS true/" /etc/havp/havp.config
   gpasswd -a clamav havp
   service clamav-daemon restart
   service havp restart
   tail /var/log/havp/error.log
   http_proxy=127.0.0.1:8080 wget http://www.eicar.org/download/eicar.com -O /tmp/eicar.com
   #if [ -f /tmp/eicar.com ];
   #  then
   #   echo "failed installing havp"
   #fi
}

EnableProxy() {
   apt-get -y install privoxy
   sed -i "s/listen-address  localhost:8118/listen-address  127.0.0.1:8118/" /etc/privoxy/config
   sed -i "s/#hostname hostname.example.org/hostname $HOSTNAMEFQDN/" /etc/privoxy/config
   service privoxy restart

   # Connect Havp & Privoxy
   sed -i "s/# PARENTPROXY localhost/PARENTPROXY 127.0.0.1/" /etc/havp/havp.config
   sed -i "s/# PARENTPORT 3128/PARENTPORT 8118/" /etc/havp/havp.config

   service havp restart
   tail /var/log/havp/error.log

   # havp complaiiiining about port 8080 so we just change it.
   sed -i "s/# PORT 8080/PORT 8082/" /etc/havp/havp.config
   service privoxy restart
   service havp restart

   # Finally Enable Transparent Proxy for havp
   sed -i "s/# TRANSPARENT false/TRANSPARENT true/" /etc/havp/havp.config
   service havp restart
}
