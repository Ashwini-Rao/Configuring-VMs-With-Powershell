#!/bin/bash
interf=`ifconfig -a | awk -- '{print $1}'| head -1| tr -d ":"`
echo -e "TYPE=ETHERNET\nBOOTPROTO=Static\nIPADDR=$1\nPREFIX=24\nGATEWAY=$2\nNAME=$interf\nSTARTMODE=auto\nONBOOT=yes" > /etc/sysconfig/network/ifcfg-$interf
hostn=$(cat /etc/hostname)
sudo sed -i "s/$hostn/$3/g" /etc/hosts
sudo sed -i "s/$hostn/$3/g" /etc/hostname

