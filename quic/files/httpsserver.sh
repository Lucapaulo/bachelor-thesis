#!/bin/sh
HOST_IP=$(echo `hostname -I`)
python ../scripts/tls.py server -k serverX509Key.pem -c serverX509Cert.pem -t TACK1.pem ${HOST_IP}:4443
