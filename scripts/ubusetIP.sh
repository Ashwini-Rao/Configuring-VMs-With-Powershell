#!/bin/bash

sudo -S su

interf=`ifconfig | awk -- '{print $1}'| head -1`

echo -e "auto lo\niface lo inet loopback\n\nauto $interf\niface $interf inet static\naddress $1\nnetmask 255.255.255.0\ngateway $2\n" > /etc/network/interfaces

hostn=$(cat /etc/hostname)
sudo sed -i "s/$hostn/$3/g" /etc/hosts
sudo sed -i "s/$hostn/$3/g" /etc/hostname

