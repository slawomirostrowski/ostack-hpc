#!/bin/bash
#
# This script installs openvpn and easy-rsa, then creates tls key and 
# certificates for server and client. By default it setup tls security
# This script is tested on centos7.2, openvpn version 2.3.12 and
# easy-rsa version 2.0
#set -x
yum -y install openvpn
yum -y install easy-rsa
#update easy-rsa vars file
cp -f vars /usr/share/easy-rsa/2.0/
# create directory for keys
export openvpn_tls_cert="/etc/openvpn/keys"
mkdir -p $openvpn_tls_cert
# copy server configuration file
cp -f server.conf $openvpn_tls_cert/../

#start the key, certification generation process
pushd /usr/share/easy-rsa/2.0/
. ./vars
./clean-all

#generate Certificate Authority
./build-ca --batch

# generate certification and private key for the vpn server
export KEY_NAME="sunserver"
./build-key-server --batch server

#generate diffie hellman pameters
./build-dh 

#generate client certification and keys
export KEY_NAME="cloudhead"
./build-key --batch cloudhead

# cloudhead* files along with ca.crt shall be copied on cloudhead node

popd





