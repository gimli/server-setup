# Ubuntu Automated Server-setup

This script is mainly for my vps users, to help them setup a brand new ubuntu 15.04 server.
also i kinda got tired of setting up servers.

Supports: Ubuntu Server 15.04

this script needs you to be root for the script to work proberly.

Download:
- this will install the script into /opt/server-setup
- $: wget -O - -q http://apt.isengard.xyz/apt.isengard.xyz.gpg.key | apt-key add -
- $: echo "deb http://apt.isengard.xyz/debian/ vivid main" > /etc/apt/sources.list.d/isengard.list
- $: apt-get update
- $: apt-get install server-setup
- $: server-setup --run-upgrade;server-setup

Or:
- $: git clone https://github.com/gimli/server-setup.git
- $: ln -s /path_to/server-setup/server-setup /usr/sbin/server-setup
- $: server-setup --run-upgrade;server-setup

and simply run: server-setup or/an server-setup --help.
ill keep working on this when i have time and perhaps in the future,
i can add other distro to. 

you'll proberly gonna find this script abit buggy still, but im working on it.
and if you have any ideas or any input write me.

Nickless
