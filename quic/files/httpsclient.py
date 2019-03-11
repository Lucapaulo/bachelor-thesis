#!/usr/bin/env python
from __future__ import print_function
from tlslite import HTTPTLSConnection, HandshakeSettings
import os

settings = HandshakeSettings()
settings.useExperimentalTackExtension = True

h = HTTPTLSConnection(os.environ["HOST_IP"], 4443, settings=settings)    
h.request("GET", "/index.html")
r = h.getresponse()
print(r.read())
