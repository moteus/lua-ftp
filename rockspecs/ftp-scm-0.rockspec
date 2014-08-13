package = "ftp"
version = "scm-0"
source = {
  url = "https://github.com/moteus/lua-ftp/archive/master.zip",
  dir = "lua-ftp-master",
}

description = {
  summary = "Simple wrapper around luasocket ftp",
  detailed = [[
  ]],
  homepage = "https://github.com/moteus/lua-ftp",
  license  = "MIT/X11",
}

dependencies = {
  "lua >= 5.1",
  "luasocket >= 2.0",
  "lua-path",
}

build = {
  type = "builtin",
  copy_directories = {},
  modules = {
    ["ftp"] = "lua/ftp.lua",
  }
}