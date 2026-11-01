#!/bin/sh

mkdir -p ~/.local/opt ~/.local/bin
cd /tmp

LUA_VERSION=5.5.1

curl -L -R -O https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
tar zxf lua-$LUA_VERSION.tar.gz
cd /tmp/lua-$LUA_VERSION
make all test
mv /tmp/lua-$LUA_VERSION/src/lua ~/.local/bin
mv /tmp/lua-$LUA_VERSION/src/luac ~/.local/bin

LUA_LS_VERSION=3.19.2

curl -L -R -O https://github.com/LuaLS/lua-language-server/releases/download/3.19.2/lua-language-server-$LUA_LS_VERSION-linux-x64.tar.gz
mkdir -p ~/.local/opt/lua-language-server
tar zxf lua-language-server-$LUA_LS_VERSION-linux-x64.tar.gz -C ~/.local/opt/lua-language-server
ln -s ~/.local/opt/lua-language-server/bin/lua-language-server ~/.local/bin/lua-language-server

