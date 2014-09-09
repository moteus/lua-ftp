lua-ftp
============
[![Licence](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENCE.txt)

Simple wrapper around LuaSocket ftp.<br/>

##Usage

```Lua
local ftp = require "ftp"

local f = ftp.new{
  host = '127.0.0.1',
  uid  = 'moteus',
  pwd  = '12345',
}

assert(f:noop())

for _, info in ipairs(f:list()) do print(info) end

f:cd('some/sub/dir')

-- upload data
f:put_data('test.txt', 'this is test message')

-- download file
f:get_file('test.txt', './local/path/test.txt')

```

##Dependences##
* [LuaSocket](http://www.impa.br/~diego/software/luasocket)
* [lua-path](https://github.com/moteus/lua-path)
