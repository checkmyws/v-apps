#!/bin/bash

sudo apt-get install -y build-essential python-dev python-pip python-virtualenv libffi-dev libcairo2

sudo mkdir /opt/graphite
sudo chown -R $USER:$USER /opt/graphite
virtualenv /opt/graphite
. /opt/graphite/bin/activate
cd $VIRTUAL_ENV

pip install 'Twisted<12.0'
pip install django==1.4.9 django-tagging

pip install carbon
pip install whisper
pip install graphite-web

pip install cairocffi
cd $VIRTUAL_ENV/lib/python2.7/site-packages/
ln -s cairocffi cairo

pip install meinheld
pip install chaussette

cd $VIRTUAL_ENV/webapp/graphite
cp local_settings.py.example local_settings.py
python manage.py syncdb

cd $VIRTUAL_ENV/conf
for f in *.conf.example; do mv "$f" "${f//.conf.example/.conf}"; done
for f in *.wsgi.example; do mv "$f" "${f//.wsgi.example/.wsgi}"; done

ln -s $VIRTUAL_ENV/conf/graphite.wsgi $VIRTUAL_ENV/webapp/wsgi.py

#$VIRTUAL_ENV/bin/carbon-cache.py start

#cd $VIRTUAL_ENV/webapp
#chaussette --host 0.0.0.0 --backend meinheld wsgi.application

sudo apt-get install -y libzmq-dev

pip install circus
pip install circus-web

cp ~/files/etc/circus/circus.ini $VIRTUAL_ENV/conf/

sudo chown -R vagrant:vagrant /opt/graphite


# dans rc.local
# . /opt/graphite/bin/activate
#$VIRTUAL_ENV/bin/carbon-cache.py start
#$VIRTUAL_ENV/bin/circusd --daemon $VIRTUAL_ENV/conf/circus.ini