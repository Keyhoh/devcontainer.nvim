#!/bin/sh

LUA_VERSION=5.5.1

cd /tmp
curl -L -R -O https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
tar zxf lua-$LUA_VERSION.tar.gz
cd /tmp/lua-$LUA_VERSION
make all test
sudo mv /tmp/lua-$LUA_VERSION/src/lua /usr/local/bin
sudo mv /tmp/lua-$LUA_VERSION/src/luac /usr/local/bin

