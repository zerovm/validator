#!/bin/bash

WORKSPACE=$HOME/workspace
DEPS="git python-debian debhelper devscripts"
DEPS="$DEPS gcc make g++-multilib devscripts debhelper autoconf automake libtool"

sudo apt-get update
sudo apt-get install --yes $DEPS

wget https://raw.githubusercontent.com/zerovm/zvm-jenkins/master/packager.py -O /tmp/packager.py

rsync -az --exclude=contrib/jenkins/.* /jenkins/ $WORKSPACE
cd $WORKSPACE
git clean -fdx

./autogen.sh
./configure
make
make clean
