#!/bin/bash

cat /root/base.conf \
    <(echo -e '<ca>') \
    /root/pki/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    /root/pki/issued/client1.crt \
    <(echo -e '</cert>\n<key>') \
    /root/pki/private/client1.key \
    <(echo -e '</key>\n<tls-auth>') \
    /etc/openvpn/ta.key \
    <(echo -e '</tls-auth>') \
    > /root/client.ovpn