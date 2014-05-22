#!/bin/bash

. /opt/graphite/bin/activate
$VIRTUAL_ENV/bin/carbon-cache.py start
$VIRTUAL_ENV/bin/circusd --daemon $VIRTUAL_ENV/conf/circus.ini