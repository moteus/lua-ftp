-- Copyright (c) 2014 Alexey Melnichuk
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local FTP   = require "socket.ftp"
local ltn12 = require "ltn12"
local path  = require "path".new("/")

local function split_status(str)
  local code, msg = string.match(str, "^(%d%d%d)%s*(.-)%s*$")
  if code then return tonumber(code), msg end
  return nil, str
end

local function split(str, sep, plain)
  local b, res = 1, {}
  while b <= #str do
    local e, e2 = string.find(str, sep, b, plain)
    if e then
      table.insert(res, (string.sub(str, b, e-1)))
      b = e2 + 1
    else
      table.insert(res, (string.sub(str, b)))
      break
    end
  end
  return res
end

local ftp = {} do
ftp.__index = ftp

function ftp:new(params)
  local t = setmetatable({}, self)
  t.private_ = {
    host = params.host;
    port = params.port;
    uid  = params.uid;
    pwd  = params.pwd;
  }
  return t
end

function ftp:cmd_(cmd, ...)
  local t = {}
  local p = {
    host     = self.private_.host;
    port     = self.private_.port;
    user     = self.private_.uid;
    password = self.private_.pwd;

    sink     = assert(ltn12.sink.table(t));
    command  = assert(cmd);
    type     = "i";
  }
  local args = table.concat({...},' ')
  if args ~= '' then
    p.command = p.command .. " " .. args
  end

  local r, e = FTP.get(p)
  if not r then return nil, e end

  return table.concat(t)
end

function ftp:list_(...)
  local f, e  = self:cmd_(...)
  if not f then
    if e then
      local code = split_status(e)
      if code and code == 550 then -- not found
        return {}
      end
    end
    return nil, e
  end
  local t = split(f, '\r?\n')
  if not t then return f end
  if t[ #t ] == '' then table.remove(t) end
  return t
end

function ftp:get(remote_file_path, snk)
  local p = {
    host     = self.private_.host;
    port     = self.private_.port;
    user     = self.private_.uid;
    password = self.private_.pwd;
    path     = self:path(remote_file_path);
    type     = "i";
    sink     = assert(snk);
  }

  return FTP.get(p)
end

function ftp:put(remote_file_path, src)
  local p = {
    host     = self.private_.host;
    port     = self.private_.port;
    user     = self.private_.uid;
    password = self.private_.pwd;
    path     = self:path(remote_file_path);
    type     = "i";
    source   = assert(src);
  }
  return FTP.put(p)
end

function ftp:cd(remote_path)
  assert(type(remote_path) == "string")

  if path:isfullpath(remote_path) then
    self.private_.path = path:normolize(remote_path)
  else
    self.private_.path = path:normolize(self:path(remote_path))
  end
  return self
end

function ftp:path(P)
  return path:join(self.private_.path or '.', P or '')
end

function ftp:noop()
  local f, e = self:cmd_("noop")
  if not f then return nil,e end
  local staus, msg = split_status(f)
  if staus == 200 then return true, msg end
  return false, f
end

function ftp:list()
  return self:list_('list', self:path())
end

function ftp:nlst(mask)
  assert(type(mask) == "string")
  return self:list_('nlst', self:path(mask))
end

function ftp:get_file(remote_file_path, local_file_path, filter)
  local f, err = io.open(local_file_path, 'wb+')
  if not f then return nil, err end
  local sink = ltn12.sink.file(f)
  if filter then sink = ltn12.sink.chain( filter, sink ) end

  local ok, err = self:get(remote_file_path, sink)
  if not ok then
    f:close()
    return nil, err
  end
  return true
end

function ftp:get_data(remote_file_path, filter)
  local t = {}
  local sink = ltn12.sink.table(t)
  if filter then sink = ltn12.sink.chain( filter, sink ) end

  local ok, err = self:get(remote_file_path, sink)
  if not ok then return nil, err end
  return table.concat(t)
end

function ftp:put_file(remote_file_path, local_file_path, filter)
  local f, err = io.open(local_file_path, 'rb')
  if not f then return nil, err end
  local src = ltn12.source.file(f)
  if filter then src = ltn12.source.chain(src, filter) end

  local ok, err = self:put(remote_file_path, src)
  if not ok then
    f:close()
    return nil, err
  end

  return true
end

function ftp:put_data(remote_file_path, data, filter)
  assert(type(data) == "string")

  local src = ltn12.source.string(data)
  if filter then
    src = ltn12.source.chain(src, filter)
  end

  local ok, err = self:put(remote_file_path, src)
  if not ok then return nil, err end

  return true
end

end

return {
  new = function(...) return ftp:new(...) end;
}
