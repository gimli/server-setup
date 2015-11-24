# Ubuntu Automated Server-setup

This script is mainly for my vps users, to help them setup a brand new ubuntu 15.04 server.
also i kinda got tired of setting up servers.

Supports: Ubuntu Server 15.04

Download:
- wget -O - -q http://apt.isengard.xyz/apt.isengard.xyz.gpg.key | apt-key add -
- echo "deb http://apt.isengard.xyz/debian/ vivid main" > /etc/apt/sources.list.d/isengard.list
- apt-get update
- apt-get install server-setup

Or:
- git clone https://github.com/gimli/server-setup.git

and simply run: server-setup or/an server-setup --help.
ill keep working on this when i have time and perhaps in the future,
i can add other distro to. 

Nickless
