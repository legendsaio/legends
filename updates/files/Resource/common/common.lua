PROPER_MODULE_PATH = MODULE_PATH

LoadModule = function(moduleName)
    local theModule = loadfile(PROPER_MODULE_PATH .. "\\" .. moduleName .. ".lua")
    if not theModule then return end
    setfenv(theModule, getfenv(2))
    return theModule()
end

-------------------- glue/glue:
_G.glue = (function()

--glue: everyday Lua functions.
--Written by Cosmin Apreutesei. Public domain.

local glue = {}

local select, pairs, tonumber, tostring, unpack, xpcall, assert =
      select, pairs, tonumber, tostring, unpack, xpcall, assert
local getmetatable, setmetatable, type, pcall =
      getmetatable, setmetatable, type, pcall
local sort, format, byte, char, min, max =
      table.sort, string.format, string.byte, string.char, math.min, math.max

function glue.clamp(x, x0, x1)
	return min(max(x, x0), x1)
end

function glue.pack(...)
	return {n = select('#', ...), ...}
end

function glue.unpack(t, i, j)
	return unpack(t, i or 1, j or t.n or #t)
end

--count the number of keys in table.
function glue.count(t, maxn)
	local n = 0
	if maxn then
		for _ in pairs(t) do
			n = n + 1
			if n >= maxn then break end
		end
	else
		for _ in pairs(t) do
			n = n + 1
		end
	end
	return n
end

--reverse keys with values.
function glue.index(t)
	local dt={}
	for k,v in pairs(t) do dt[v]=k end
	return dt
end

--list of keys, optionally sorted.
function glue.keys(t, cmp)
	local dt={}
	for k in pairs(t) do
		dt[#dt+1]=k
	end
	if cmp == true then
		sort(dt)
	elseif cmp then
		sort(dt, cmp)
	end
	return dt
end

--stateless pairs() that iterate elements in key order.
local keys = glue.keys
function glue.sortedpairs(t, cmp)
	local kt = keys(t, cmp or true)
	local i = 0
	return function()
		i = i + 1
		return kt[i], t[kt[i]]
	end
end

--update a table with the contents of other table(s).
function glue.update(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t ~= nil then
			for k,v in pairs(t) do dt[k]=v end
		end
	end
	return dt
end

--add the contents of other table(s) without overwrite.
function glue.merge(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t ~= nil then
			for k,v in pairs(t) do
				if dt[k] == nil then dt[k]=v end
			end
		end
	end
	return dt
end

--scan list for value.
function glue.indexof(v, t)
	for i=1,#t do
		if t[i] == v then
			return i
		end
	end
end

--extend a list with the elements of other lists.
function glue.extend(dt,...)
	for j=1,select('#',...) do
		local t=select(j,...)
		if t ~= nil then
			for i=1,#t do dt[#dt+1]=t[i] end
		end
	end
	return dt
end

--append non-nil arguments to a list.
function glue.append(dt,...)
	for i=1,select('#',...) do
		dt[#dt+1] = select(i,...)
	end
	return dt
end

local tinsert, tremove = table.insert, table.remove

--insert n elements at i, shifting elemens on the right of i (i inclusive)
--to the right.
local function insert(t, i, n)
	if n == 1 then --shift 1
		tinsert(t, i, t[i])
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive)
--to the left.
local function remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		tremove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--shift all the elements to the right of i (i inclusive) to the left
--or further to the right.
function glue.shift(t, i, n)
	if n > 0 then
		insert(t, i, n)
	elseif n < 0 then
		remove(t, i, -n)
	end
	return t
end

--reverse elements of a list in place.
function glue.reverse(t)
	local len = #t+1
	for i = 1, (len-1)/2 do
		t[i], t[len-i] = t[len-i], t[i]
	end
	return t
end

--string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--split a string by a separator that can be a pattern or a plain string.
--return a stateless iterator for the pieces.
local function iterate_once(s, s1)
	return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
	start = start or 1
	plain = plain or false
	if not s:find(sep, start, plain) then
		return iterate_once, s
	end
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true return s end
		return pass(s:find(sep, start, plain))
	end
end

--string trim12 from lua wiki.
function glue.string.trim(s)
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--escape a string so that it can be taken literally inside a pattern.
local function format_ci_pat(c)
	return format('[%s%s]', c:lower(), c:upper())
end
function glue.string.escape(s, mode)
	s = s:gsub('%%','%%%%'):gsub('%z','%%z')
		:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
	if mode == '*i' then s = s:gsub('[%a]', format_ci_pat) end
	return s
end

--string to hex.
function glue.string.tohex(s, upper)
	if type(s) == 'number' then
		return format(upper and '%08.8X' or '%08.8x', s)
	end
	if upper then
		return (s:gsub('.', function(c)
		  return format('%02X', byte(c))
		end))
	else
		return (s:gsub('.', function(c)
		  return format('%02x', byte(c))
		end))
	end
end

--hex to string.
function glue.string.fromhex(s)
	return (s:gsub('..', function(cc)
	  return char(tonumber(cc, 16))
	end))
end

--publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

--run an iterator and collect the n-th return value into a list.
local function select_at(i,...)
	return ...,select(i,...)
end
local function collect_at(i,f,s,v)
	local t = {}
	repeat
		v,t[#t+1] = select_at(i,f(s,v))
	until v == nil
	return t
end
local function collect_first(f,s,v)
	local t = {}
	repeat
		v = f(s,v); t[#t+1] = v
	until v == nil
	return t
end
function glue.collect(n,...)
	if type(n) == 'number' then
		return collect_at(n,...)
	else
		return collect_first(n,...)
	end
end

--no-op filter.
function glue.pass(...) return ... end

--set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
	local meta = getmetatable(t)
	if meta then
		meta.__index = parent
	elseif parent ~= nil then
		setmetatable(t, {__index = parent})
	end
	return t
end

--get the value of a table field, and if the field is not present in the
--table, create it as an empty table, and return it.
function glue.attr(t, k, v0)
	local v = t[k]
	if v == nil then
		if v0 == nil then
			v0 = {}
		end
		v = v0
		t[k] = v
	end
	return v
end

--set up a table so that missing keys are created automatically as autotables.
local autotable
local auto_meta = {
	__index = function(t, k)
		t[k] = autotable()
		return t[k]
	end,
}
function autotable(t)
	t = t or {}
	local meta = getmetatable(t)
	if meta then
		assert(not meta.__index or meta.__index == auto_meta.__index,
			'__index already set')
		meta.__index = auto_meta.__index
	else
		setmetatable(t, auto_meta)
	end
	return t
end
glue.autotable = autotable

--check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
	local f = io.open(name, mode or 'rb')
	if f then f:close() end
	return f ~= nil and name or nil
end

glue.fileexists = glue.canopen --for backwards compat.

--read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
	open = open or io.open
	local f, err = open(name, mode=='t' and 'r' or 'rb')
	if not f then return nil, err end
	local s, err = f:read'*a'
	if s == nil then return nil, err end
	f:close()
	return s
end

--read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
	return glue.readfile(cmd, mode, open or io.popen)
end

--write a string, number, or table to a file (in binary mode by default).
--if the write fails, the file is removed and an error is raised.
function glue.writefile(filename, s, mode)
	local f, err = io.open(filename, mode=='t' and 'w' or 'wb')
	if not f then
		error(err)
	end
	local function check(ret, err)
		if ret ~= nil then return ret, err end
		f:close()
		local ret, err2 = os.remove(filename)
		if ret == nil then
			err = err .. '\n' .. err2
		end
		error(err, 2)
	end
	if type(s) == 'table' then
		for i = 1, #s do
			check(f:write(s[i]))
		end
	elseif type(s) == 'function' then
		while true do
			local _, s1 = check(xpcall(s, debug.traceback))
			if not s1 then break end
			check(f:write(s1))
		end
	else
		check(f:write(s))
	end
	f:close()
end

--assert() with string formatting (this should be a Lua built-in).
function glue.assert(v, err, ...)
	if v then return v,err,... end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then err = format(err,...) end
	error(err, 2)
end

--pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
	return tostring(e) .. '\n' .. debug.traceback()
end
function glue.pcall(f, ...)
	return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end --to distinguish from error.
	return result, ...
end

--wrap a function that raises errors on failure into a function that follows
--the Lua convention of returning nil,err on failure.
function glue.protect(func)
	return function(...)
		return unprotect(pcall(func, ...))
	end
end

--pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
--NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f,...)
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i](e) end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return ok,...
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
	return unprotect(fpcall(...))
end

--fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
	if not ok then error(..., 2) end
	return ...
end
function glue.fcall(...)
	return assert_fpcall(fpcall(...))
end

--portable way to get script's directory, based on arg[0].
--NOTE: the path is not absolute, but relative to the current directory!
--NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, 'arg') and arg[0] and arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
glue.bin = dir == '' and '.' or dir

--portable way to add more paths to package.path, at any place in the list.
--negative indices count from the end of the list like string.sub(). index 'after' means 0.
function glue.luapath(path, index, ext)
	ext = ext or 'lua'
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. psep .. 'init.' .. ext)
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.path = table.concat(paths, tsep)
end

--portable way to add more paths to package.cpath, at any place in the list.
--negative indices count from the end of the list like string.sub(). index 'after' means 0.
function glue.cpath(path, index)
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local ext = package.cpath:match('%.([%a]+)%'..tsep..'?') --dll | so | dylib
	local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.cpath = table.concat(paths, tsep)
end
local jit = true
if jit then
ffi.cdef[[
	void* malloc (size_t size);
	void  free   (void*);
]]

function glue.malloc(ctype, size)
	if type(ctype) == 'number' then
		ctype, size = 'char', ctype
	end
	local ctype = ffi.typeof(ctype or 'char')
	local ctype = size and ffi.typeof('$(&)[$]', ctype, size) or ffi.typeof('$&', ctype)
	local bytes = ffi.sizeof(ctype)
	local data  = ffi.cast(ctype, ffi.C.malloc(bytes))
	assert(data ~= nil, 'out of memory')
	ffi.gc(data, glue.free)
	return data
end

function glue.free(cdata)
	ffi.gc(cdata, nil)
	ffi.C.free(cdata)
end

local intptr_ct = ffi.typeof'intptr_t'
local intptrptr_ct = ffi.typeof'const intptr_t*'
local intptr1_ct = ffi.typeof'intptr_t[1]'
local voidptr_ct = ffi.typeof'void*'

--x86: convert a pointer's address to a Lua number.
local function addr32(p)
	return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
end

--x86: convert a number to a pointer, optionally specifying a ctype.
local function ptr32(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	return ffi.cast(ctype, addr)
end

--x64: convert a pointer's address to a Lua number or possibly string.
local function addr64(p)
	local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
   local n = tonumber(np)
	if ffi.cast(intptr_ct, n) ~= np then
		--address too big (ASLR? tagged pointers?): convert to string.
		return ffi.string(intptr1_ct(np), 8)
	end
	return n
end

--x64: convert a number or string to a pointer, optionally specifying a ctype.
local function ptr64(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	if type(addr) == 'string' then
		return ffi.cast(ctype, ffi.cast(voidptr_ct,
			ffi.cast(intptrptr_ct, addr)[0]))
	else
		return ffi.cast(ctype, addr)
	end
end

glue.addr = ffi.abi'64bit' and addr64 or addr32
glue.ptr = ffi.abi'64bit' and ptr64 or ptr32

end --if jit

return glue

end)()
-------------------- oo/oo:
_G.oo = (function()
--[[
local callCount = 0
local startTick = 0
local lastCallTick = 0
local totalExecutionTime = 0
local function noobProfilerHook1()
	if callCount == 0 then
		startTick = os.clock()
	end
	callCount = callCount + 1
	lastCallTick = os.clock()
end
local function noobProfilerHook2()
	totalExecutionTime = totalExecutionTime + (os.clock() - lastCallTick)
end
local function resetNoobProfilerHook()
	callCount = 0
	totalExecutionTime = 0
end
Callback.Bind(Callback.OnDraw, function()
	if callCount > 0 then
		local timeElapsed = os.clock() - startTick
		if timeElapsed >= 1.0 then
			print(timeElapsed .. "s", "calls: " .. callCount,  totalExecutionTime)
			resetNoobProfilerHook()
		end
	end
end, 100)
]]

--object system with virtual properties and method overriding hooks.
--Written by Cosmin Apreutesei. Public Domain.

local Object = {
	classname = "Object",
	_getters = {},
	_setters = {},
	_state = {},
}

local function class(super,...)
	return (super or Object):subclass(...)
end

function Object:subclass()
	return setmetatable({super = self, classname = '', _getters = {}, _setters = {}, _state = {}}, getmetatable(self))
end

function Object:init(...) end

function Object:create(...)
	local o = setmetatable({super = self, _getters = {}, _setters = {}, _state = {}}, getmetatable(self))
	o:init(...)
	return o
end

local meta = {}

function meta.__call(o,...)
	return o:create(...)
end

local lastK
local donezo = false
function meta.__index(o,k)
	if not donezo and (k == "_getters" or k == "_setters") then
		donezo = true
		print(k, lastK)
		print(o)
		print(rawget(o, "_getters"))
		print(rawget(o, "_setters"))
	end
	lastK = k
	if o._getters[k] then
		return o._getters[k](o, k)
	elseif o._setters[k] then
		return o._state[k]
	elseif rawget(o, "super") then
		return rawget(o, "super")[k]
	end
end

function meta.__newindex(o,k,v)
	if type(k) == 'string' then
		if o._getters[k] then -- virtual property
			if o._setters[k] then -- r/w property
				o._setters[k](o, v)
			else -- r/o property
				error(string.format('trying to set read only property "%s"', k))
			end
		elseif o._setters[k] then -- stored property
			o._setters[k](o, v)
			o._state[k] = v
		else
			rawset(o, k, v)
		end
	else
		rawset(o, k, v)
	end
end

local function noop() end
local function pass(...) return ... end

function Object:before(method_name, hook)
	local method = self[method_name] or pass
	rawset(self, method_name, function(self, ...)
		return method(self, hook(self, ...))
	end)
end

function Object:after(method_name, hook)
	local method = self[method_name] or pass
	rawset(self, method_name, function(self, ...)
		return hook(self, method(self, ...))
	end)
end

function Object:override(method_name, hook)
	local method = self[method_name] or noop
	rawset(self, method_name, function(self, ...)
		return hook(self, method, ...)
	end)
end

function Object:getproperty(k)
	if type(k) == 'string' and rawget(self, 'get_'..k) then --virtual property
		return rawget(self, 'get_'..k)(self, k)
	elseif rawget(self, 'set_'..k) then --stored property
		if rawget(self, 'state') then
			return self.state[k]
		end
	elseif rawget(self, 'super') then --inherited property
		return rawget(self, 'super')[k]
	end
end
--[[
function Object:getproperty(k)
	local result = Object_getproperty(self, k)
	return result
end
]]

function Object:setproperty(k,v)
	if type(k) == 'string' then
		if rawget(self, 'get_'..k) then --virtual property
			if rawget(self, 'set_'..k) then --r/w property
				rawget(self, 'set_'..k)(self, v)
			else --r/o property
				error(string.format('trying to set read only property "%s"', k))
			end
		elseif rawget(self, 'set_'..k) then --stored property
			if not rawget(self, 'state') then rawset(self, 'state', {}) end
			rawget(self, 'set_'..k)(self, v) --if the setter breaks, the property is not updated
			self.state[k] = v
		elseif k:find'^before_' then --install before hook
			local method_name = k:match'^before_(.*)'
			self:before(method_name, v)
		elseif k:find'^after_' then --install after hook
			local method_name = k:match'^after_(.*)'
			self:after(method_name, v)
		elseif k:find'^override_' then --install override hook
			local method_name = k:match'^override_(.*)'
			self:override(method_name, v)
		else
			rawset(self, k, v)
		end
	else
		rawset(self, k, v)
	end
end

--returns iterator<k,v,source>; iterates bottom-up in the inheritance chain
function Object:allpairs()
	local source = self
	local k,v
	return function()
		k,v = next(source,k)
		if k == nil then
			source = source.super
			if source == nil then return end
			k,v = next(source)
		end
		return k,v,source
	end
end

--returns all properties including the inherited ones and their current values
function Object:properties()
	local values = {}
	for k,v,source in self:allpairs() do
		if values[k] == nil then
			values[k] = v
		end
	end
	return values
end

function Object:inherit(other, override)
	local properties = other:properties()
	for k,v in pairs(properties) do
		if (override or rawget(self, k) == nil)
			and k ~= 'classname' --we keep our classname (we don't change our identity)
			and k ~= 'super' --we keep our super (we don't change the dynamic inheritance)
		then
			rawset(self, k, v)
		end
	end
	--copy metafields if metatables are different
	local src_meta = getmetatable(other)
	local dst_meta = getmetatable(self)
	if src_meta ~= dst_meta then
		for k,v in pairs(src_meta) do
			if override or rawget(dst_meta, k) == nil then
				rawset(dst_meta, k, v)
			end
		end
	end
end

function Object:detach()
	self:inherit(self.super)
	self.classname = self.classname --if we're an instance, we would have no classname
	self.super = nil
end

function Object:gen_properties(names, getter, setter)
	for k in pairs(names) do
		if getter then
			self._getters[k] = function(self) return getter(self, k) end
		end
		if setter then
			self._setters[k] = function(self, v) return setter(self, k, v) end
		end
	end
end

setmetatable(Object, meta)

return setmetatable({
	class = class,
	Object = Object,
}, {
	__index = function(t,k)
		return function(super, ...)
			if type(super) == 'string' then
				super = t[super]
			end
			local cls = class(super, ...)
			cls.classname = k
			t[k] = cls
			return cls
		end
	end
})

end)()

-- Standard Lua library extensions:
-------------------- lua-extensions/_table:
do
--[[
    table extensions
]]

function table.clear(t)
    for i, v in pairs(t) do
        t[i] = nil
    end
end

function table.copy(from, deepCopy)
    local to = {}
    for k, v in pairs(from) do
        if deepCopy and type(v) == "table" then to[k] = table.copy(v, true)
        else to[k] = v
        end
    end
    return to
end

function table.contains(t, what, member) --member is optional
    for i, v in pairs(t) do
        if member and v[member] == what or v == what then return i, v end
    end
end

local tabChars = "    "
function table.serialize(t, tab)
    local s, len = {"{\n"}, 1
    for i, v in pairs(t) do
        local iType, vType = type(i), type(v)
        if tab then
            s[len+1] = tab
            len = len + 1
        end
        s[len+1] = tabChars
        if iType == "number" then
            s[len+2], s[len+3], s[len+4] = "[", i, "]"
        elseif iType == "string" then
            s[len+2], s[len+3], s[len+4] = '["', i, '"]'
        end
        s[len+5] = " = "
        if vType == "number" then
            s[len+6], s[len+7], len = v, ",\n", len + 7
        elseif vType == "string" then
            s[len+6], s[len+7], s[len+8], len = '"', v:unescape(), '",\n', len + 8
        elseif vType == "table" then
            s[len+6], s[len+7], len = table.serialize(v, (tab or "") .. tabChars), ",\n", len + 7
        elseif vType == "boolean" then
            s[len+6], s[len+7], len = tostring(v), ",\n", len + 7
        elseif vType == "function" or vType == "userdata" then
            s[len+6], s[len+7], len = vType, ",\n", len + 7
        end
    end
    if tab then
        s[len+1] = tab
        len = len + 1
    end
    s[len+1] = "}"
    return table.concat(s)
end

function table.merge(base, t, deepMerge)
    for i, v in pairs(t) do
        if deepMerge and type(v) == "table" and type(base[i]) == "table" then
            base[i] = table.merge(base[i], v)
        else base[i] = v
        end
    end
    return base
end

function table.combine(base, t)
    for k,  v in pairs(t) do
        table.insert(base, v)
    end
    return base
end

function table.extract(t, p)
    local n = {}
    for k, v in pairs(t) do
        if v[p] then
            table.insert(n, v[p])
        end
    end
    return n
end

function table.count(t)
    return glue.count(t)
end

function table.shuffle(t)
	for i = 1, #t, 1 do
		local j = math.random(#t)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function table.isArray(t)
    if (type(t) ~= 'table') then return false end

    for k, v in pairs(t) do
        if type(k) ~= 'number' then return false end
    end

    return table.count(t) > 0
end

function table.isObject(t)
    if (type(t) ~= 'table') then return false end

    return not table.isArray(t)
end

function table.flip(t)
    return glue.index(t)
end

end

-------------------- lua-extensions/_math:
do
--[[
    math extensions
]]

function math.isNaN(num)
    return num ~= num
end

function math.isInf(num)
    return num == math.huge or num == -math.huge
end

function math.isFinite(num)
    return num > -math.huge and num < math.huge
end

-- Round half away from zero
function math.round(num, idp)
    local mult = 10 ^ (idp or 0)
    if num >= 0 then
        return math.floor(num * mult + 0.5) / mult
    else
        return math.ceil(num * mult - 0.5) / mult
    end
end

function math.round2(num, idp)
    local mult = 10 ^ (idp or 0)
    if num >= 0 then
        return math.truncate(math.floor(num * mult + 0.5) / mult, idp)
    else
        return math.truncate(math.ceil(num * mult - 0.5) / mult, idp)
    end
end

function math.close(a, b, eps)
    eps = eps or 1e-9
    return math.abs(a - b) <= eps
end

function math.limit(val, min, max)
    return math.min(max, math.max(min, val))
end
math.clamp = math.limit

function math.truncate(num, idp)
    num = tostring(num)
    local fp = num:find("%.")
    return fp and tonumber(num:sub(1, (fp-1)+(idp and idp > 0 and idp+1 or 0))) or tonumber(num)
end

function math.randomFloat(min, max)
    return (min or 0) + math.random() * ((max or 9999999) - (min or 0))
end

end

-------------------- lua-extensions/_string:
do
--[[
    string extensions
]]

function string.split(str, delim, maxNb)    -- http://lua-users.org/wiki/SplitJoin
    -- Eliminate bad cases...
    if not delim or delim == "" or string.find(str, delim) == nil then
        return { str }
    end
    maxNb = (maxNb and maxNb >= 1) and maxNb or 0
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        if nb == maxNb then
            result[nb] = lastPos and string.sub(str, lastPos, #str) or str
            break
        end
        result[nb] = part
        lastPos = pos
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function string.join(arg, del)
    return table.concat(arg, del)
end

function string.trim(s)
    return s:match'^%s*(.*%S)' or ''
end

function string.escape(s)
    return s:gsub(".",{
        ["\a"] = [[\a]],
        ["\b"] = [[\b]],
        ["\f"] = [[\f]],
        ["\n"] = [[\n]],
        ["\r"] = [[\r]],
        ["\t"] = [[\t]],
        ["\v"] = [[\v]],
        ["\\"] = [[\\]],
        ['"'] = [[\"]],
        ["'"] = [[\']],
        ["["] = "\\[",
        ["]"] = "\\]",
      })
end

function string.unescape(s)
    return s:gsub(".",{
        ["\\"] = ''
      })
end

function string.encodeUrl(str)
  --Ensure all newlines are in CRLF form
  str = string.gsub (str, "\r?\n", "\r\n")

  --Percent-encode all non-unreserved characters
  --as per RFC 3986, Section 2.3
  --(except for space, which gets plus-encoded)
  str = string.gsub (str, "([^%w%-%.%_%~ ])",
    function (c) return string.format ("%%%02X", string.byte(c)) end)

  --Convert spaces to plus signs
  str = string.gsub (str, " ", "+")

  return str
end

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

local Game_GetTime = Game.GetTime

function string.random(length)
  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

end


-------------------- vkeys/vkey:
_G.VKey = (function()
return {
    LButton = 1,
    RButton = 2,
    Cancel = 3,
    MButton = 4,
    Back = 8,
    Tab = 9,
    Clear = 12,
    Return = 13,
    Shift = 16,
    Control = 17,
    Menu = 18,
    Pause = 19,
    Capital = 20,
    Escape = 27,
    Space = 32,
    Prior = 33,
    Next = 34,
    End = 35,
    Home = 36,
    Left = 37,
    Up = 38,
    Right = 39,
    Down = 40,
    Select = 41,
    Print = 42,
    Execute = 43,
    Snapshot = 44,
    Insert = 45,
    Delete = 46,
    Help = 47,
    Number0 = 48,
    Number1 = 49,
    Number2 = 50,
    Number3 = 51,
    Number4 = 52,
    Number5 = 53,
    Number6 = 54,
    Number7 = 55,
    Number8 = 56,
    Number9 = 57,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LWin = 91,
    RWin = 92,
    Apps = 93,
    Numpad0 = 96,
    Numpad1 = 97,
    Numpad2 = 98,
    Numpad3 = 99,
    Numpad4 = 100,
    Numpad5 = 101,
    Numpad6 = 102,
    Numpad7 = 103,
    Numpad8 = 104,
    Numpad9 = 105,
    Multiply = 106,
    Add = 107,
    Separator = 108,
    Subtract = 109,
    Decimal = 110,
    Divide = 111,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    F13 = 124,
    F14 = 125,
    F15 = 126,
    F16 = 127,
    F17 = 128,
    F18 = 129,
    F19 = 130,
    F20 = 131,
    F21 = 132,
    F22 = 133,
    F23 = 134,
    F24 = 135,
    NumLock = 144,
    Scroll = 145,
    LShift = 160,
    LControl = 162,
    LMenu = 164,
    RShift = 161,
    RControl = 163,
    RMenu = 165,
    VolumeMute = 0xAD,
    VolumeDown = 0xAE,
    VolumeUp = 0xAF,
    MediaNextTrack = 0xB0,
    MediaPreviousTrack = 0xB1,
    MediaPlayPause = 0xB3
}

end)()
-------------------- vkeys/vmessage:
_G.VMessage = (function()
return {
    KeyDown = 256,
    KeyUp = 257,
    Scroll = 522
}

end)()

-------------------- print/print:
_G.Print = (function()
local pLib = {}
local flashName = nil

pLib.infoColor = 'D8D8D8'
pLib.successColor = '00FF1F'
pLib.warningColor = 'FFA600'
pLib.dangerColor = 'FF001F'

function pLib._print(message, color)
    -- if (Game.IsExiting()) then return end

    PrintChat('<font color="#40C1FF">' .. (flashName or getfenv(3).MODULE_NAME_FRIENDLY or getfenv(3).MODULE_NAME or MODULE_NAME) .. ':</font> ' .. '<font color="#' .. color .. '">' .. message .. '</font>')

    -- if (LS_DEBUG) then
    --     PrintConsole('[' .. (flashName or getfenv(3).MODULE_NAME_FRIENDLY or getfenv(3).MODULE_NAME or MODULE_NAME) .. '] ' .. message .. '\n')
    -- end

    flashName = nil
end

function pLib.Name(name)
    flashName = name
end

function pLib.Info(message)
    pLib._print(message, pLib.infoColor)
end

function pLib.Success(message)
    pLib._print(message, pLib.successColor)
end

function pLib.Warning(message)
    pLib._print(message, pLib.warningColor)
end

function pLib.Danger(message)
    pLib._print(message, pLib.dangerColor)
end

function pLib.Debug(...)
    if (not LS_DEBUG) then return end
    print(...)
end

-- function pLib.DebugView(...)
--     if (not LS_DEBUG) then return end
--     dprint(...)
-- end

function pLib.Clear()
    -- if (Game.IsExiting()) then return end

    for i = 1, 20 do
        PrintChat('&nbsp;')
    end

    if (not LS_DEBUG) then return end

    -- for i = 1, 100 do
    --     Game.PrintConsole('\n\r')
    -- end

    -- dclear()
end

return pLib

end)()

-------------------- utility/utility:
do
--[[
    Utility functions and classes
]]

local Player = Game.localPlayer;

local function ToBoolean(arg)
    return not not arg
end

_G.toboolean = ToBoolean

local function Try(f, c)
    if (type(f) == 'string') then
        f = loadstring(f)
    end

    local p, r = pcall(f)
    if (not p) then
        return c(r)
    end
    return r
end

_G.try = Try

local function Catch(f)
    return f
end

_G.catch = Catch

local table_flip = table.flip

-- Get Enum Name:
function GetEnumName(enumTable, enum)
    for k, v in pairs(enumTable) do
        if (v == enum) then
            return k
        end
    end

    return nil
end

-- RollChance:
function RollChance(chance)
    return math.random() * 100 < chance
end

--[[
    Prints a string in DebugView. It's passing raw null-terminated direct string.
    DebugView++     https://debugviewpp.wordpress.com/2014/01/04/7/
    DebugView       https://technet.microsoft.com/en-us/sysinternals/debugview.aspx

    Common.OutputDebugString(<string> str)
        <string>     str     Automatically casted to string, so you can pass numbers etc.

    Examples:
        Common.OutputDebugString("hello!")
        Common.OutputDebugString(2+2)
]]
-- if (LS_DEBUG) then
--     ffi.cdef[[
--         void OutputDebugStringA(char*);
--     ]]
-- end
-- local function OutputDebugString(str)
--     if (not LS_DEBUG) then return end
--     ffi.C.OutputDebugStringA(ffi.cast("char*", tostring(str) .. "\0"))
-- end

_print = print
local function uPrint(isDebug, ...)
    if isDebug then
        --OutputDebugString(...)
    elseif PrintChat then
        PrintChat(...)
    else
        _print(...)
    end
end

--[[
    Universal print wrapper with built-in pretty-print.

    print(<vararg> ...)

    Examples:
        print("hey")
        print("hello", "kitty")
        print({1,2,3}, {a,b,c}, 1337, "hi")
]]
local tab = "    "
local function PPFormat(prefix, ...)
    local t = { ... }
    for i = 1, #t do
        local v = t[i]
        local _type = type(v)
        if _type == "string" then t[i] = v
        elseif _type == "number" then t[i] = tostring(v)
        elseif _type == "table" then t[i] = table.serialize(v)
        elseif _type == "boolean" then t[i] = v and "true " or "false "
        elseif _type == "userdata" then t[i] = tostring(v)
        elseif _type == "function" then t[i] = tostring(v)
        else t[i] = _type
        end
    end
    local output = #t > 0 and string.join(t, tab) or "nil"
    if prefix then
        local split = output:split("\n")
        for i, v in pairs(split) do
            split[i] = prefix .. tab .. v .. "\n"
        end
        output = string.join(split)
    end
    return output
end

function _Print(...)
    uPrint(false, PPFormat(nil, ...))
end

print = _Print
_G.print = print

-- Restore:
Callback.Bind(CallbackType.OnUnload, function()
    _G.print = _print
end)

--[[
    Pretty print version of OutputDebugString.
    It's same as normal Common.Print, but it prints in DebugView instead of game chat and/or console.
    Also it automatically adds prefix "LS |" to each line by default, so you can use filter "LS |*" in DebugView.
    It's possible to change the prefix to anything you want with Common.SetDebugPrefix(<string> prefix)

    Common.DebugPrint(<vararg> ...)
        <vargarg>   ...     Anything you want: tables, strings, functions, numbers, userdata, etc.

    Examples:
        Common.DebugPrint("test", 123, 10+20, { 1, 2, 3})
        dprint({1, 2, 3, fn = function() end})
]]
-- local debugPrefix = "LS |"
-- function DebugPrint(...)
--     uPrint(true, PPFormat(debugPrefix, ...))
-- end
-- _G.dprint = DebugPrint

--[[
    Allows you to change the default debug prefix to anything you want.

    Common.SetDebugPrefix(<string> prefix)
        <string>    prefix  Any string.

    Example:
        Common.SetDebugPrefix("MyStuff |")
]]
-- function SetDebugPrefix(prefix)
--     assert(type(prefix) == "string", "Common.SetDebugPrefix: wrong argument types (<string> prefix)")
--     debugPrefix = prefix
-- end

--[[
    Clears DebugView
]]
-- function DebugClear()
--     DebugPrint("DBGVIEWCLEAR")
-- end
-- _G.dclear = DebugClear


-- function ReadFile(path)
--     assert(type(path) == "string", "Game.ReadAnyFile: wrong argument types (<string> expected for path)")
--     local file = io.open(path, "r")
--     if not file then return end
--     local text = file:read("*all")
--     file:close()
--     return text
-- end

--[[
    Simple test solution.
    Testing function fn. Prints SUCCESS if returns true and FAILURE otherwise.

    <boolean>   Common.SimpleTestAPI(<string> name, <function> fn)
        <string>    name    Name of the test
        <function>  fn      Test function itself

    Example:
        Common.SimpleTestAPI("math.isNaN", function()
            return math.isNaN(0/0)
        end)

    Template:
        Common.SimpleTestAPI("", function()
            return true
        end)
]]
function SimpleTestAPI(name, fn)
    assert(type(name) == "string" and type(fn) == "function", "Common.SimpleTestAPI: wrong argument types (<string> name, <function> fn)")
    local result = fn()
    print("[SimpleTestAPI]", name .. ": ", (result and "SUCCESS" or "FAILURE"))
    return result
end

--[[
    Adding time library stuff to Time namespace
    It's more precise time functions based on QueryPerformanceCounter()
]]
-- local time = Environment.LoadModule("time/time")
-- _G.Time = {
--     GetClockPrecise = time.clock,
--     GetClockPreciseMs = function() return time.clock() * 1000 end,
--     GetTickCount = time.tick,
--     Sleep = time.sleep
-- }
-- math.randomseed(time.clock() + Game.GetTime() + os.clock())
math.randomseed(Game.GetTime() + os.clock())


--[[
    Queue Class

    Queue implementation based on table.insert and table.remove.
    In LuaJIT it's almost as fast as alternative implementation from https://www.lua.org/pil/11.4.html
    Even though it's slightly slower - it provides much more functionality.

    <Queue> Queue()                             Returns empty Queue instance.
    <Queue> Queue(<table> t)                    Return Queue instance based on table with elements with index starting from 1.

    Queue:PushLeft(<*> value)                   Push the value to the beginning of the queue.
    Queue:PushRight(<*> value)                  Push the value to the end of the queue.
    Queue:PopLeft()                             Pop the value from the beginning of the queue. Returns the popped value.
    Queue:PopRight()                            Pop the value from the end of the queue. Returns the popped value.
    Queue:Pairs()                               Iterator. Implemented as pairs(Queue.list).
    Queue:__newindex(<number> key, <*> value)   You can push values directly even in the middle of the queue. Implemented as table.insert(Queue.list, key, value)

    Examples:
        local q = Queue({1, 2, 3})
        q:PushLeft(1)
        q:PushRight(2)
        q:PushLeft(0)
        for i=1, #q do
            print(q[i])
        end

        local q = Queue()
        q:PushRight(function() print("Action 1") end)
        q:PushRight(function()
            print("Action 2")
            q:PushLeft(function() print("Top Priority Action!") end)
        end)
        q:PushRight(function() print("Action 3") end)
        while #q > 0 do
            q:PopLeft()()
        end
]]
function Queue(t)
    local _t = {}
    if t and type(t) == "table" then
        for i, v in ipairs(t) do
            _t[i] = v
        end
    end
    local _queue = { list = _t }
    _queue.PushLeft = function(self, value)
        table.insert(self.list, 1, value)
    end
    _queue.PushRight = function(self, value)
        self.list[#self.list + 1] = value
    end
    _queue.PopLeft = function(self)
        return table.remove(self.list, 1)
    end
    _queue.PopRight = function(self)
        return table.remove(self.list, #self)
    end
    _queue.PopIndex = function(self, index)
        return table.remove(self.list, index)
    end
    _queue.Pairs = function(self)
        return pairs(self.list)
    end
    _queue.pairs, _queue.ipairs = _queue.Pairs, _queue.Pairs
    _queue.Clear = function(self)
        for i = #self, 1, -1 do
            self:PopRight()
        end
    end
    _queue.Shuffle = function(self)
        local j
        for i = #self, 2, -1 do
            j = math.random(i)
            self.list[i], self.list[j] = self.list[j], self.list[i]
        end
    end
    setmetatable(_queue, {
        __index = function(self, key)
            if type(key) == "number" then
                return self.list[key]
            end
        end,
        __newindex = function(self, key, value)
            assert(type(key) == "number", "Common.Queue: wrong argument type (<number> key)")
            assert(key >= 1 and key <= #self + 1, "Common.Queue: key is out of range")
            assert(value ~= nil, "Common.Queue: wrong argument type (<*> value can't be nil)")
            table.insert(self.list, key, value)
        end,
        __len = function(self)
            return #self.list
        end
    })
    return _queue
end

local Game_GetTime = Game.GetTime
local Callback_OnTick = Callback.OnTick
local Callback_Bind = Callback.Bind
local Callback_OnDraw = Callback.OnDraw
local CallbackResult_Dispose = CallbackResult.Dispose

function SecondsToClock(seconds)
    local mins = string.format('%02.f', math.floor(seconds / 60))
    local secs = string.format('%02.f', math.floor(seconds - mins * 60))
    return mins .. ':' .. secs
end

-- DelayAction
function DelayAction(act, sec)
    local time_due = Game_GetTime() + sec
    Callback_Bind(Callback_OnTick, function(t)
        if Game_GetTime() > time_due then
            act()
            return CallbackResult_Dispose
        end
    end)
end

-- DelayActionPrecise
function DelayActionPrecise(act, sec)
    local time_due = Game_GetTime() + sec
    Callback_Bind(Callback_OnDraw, function(t)
        if Game_GetTime() > time_due then
            act()
            return CallbackResult_Dispose
        end
    end)
end

-- DelayActionFrames
function DelayActionFrames(f, frames)
    Callback.Bind(Callback.OnDraw, function(t)
        if (frames <= 0) then
            f()
            return CallbackResult.Dispose
        end

        frames = frames - 1
    end)
end

--[[
    Champions related Functions and Helpers
]]

_G.EnemiesInGame = {}
for i, enemy in ObjectManager.enemyHeroes:pairs() do
    EnemiesInGame[tostring(enemy.charName)] = enemy.networkId
end

function ValidTarget2(target)
    if target ~= nil and target:IsValidTarget() and target.team ~= Player.team and target.isAlive
        and target.type == Player.type and not Common.IsUnitImmune(target) then
        return true
    else
        return false
    end
end

function GetDistance2(p1, p2)
    p1 = p1 or Player.position
    p2 = p2 or Player.position
    local x, z = p1.x - p2.x, (p1.z or p1.y) - (p2.z or p2.y)
    return math.sqrt(x * x + z * z)
end

-- Keep the short-lived enemy movement history used by FH champion modules.
-- LegendSense's original Common library refreshes this state on LagFree(0)
-- before champion-specific gap-close and prediction logic runs.
EnemyPositionHistory = EnemyPositionHistory or {}

function RefreshEnemyPos()
    local now = Game.GetTickCount()

    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy:IsValid() and enemy.isAlive then
            local handle = enemy.handle
            local current = enemy.position:Copy()
            local history = EnemyPositionHistory[handle]

            if history then
                local elapsed = now - (history.time or now)
                local moved = history.pos and Common.GetDistance2(history.pos, current) or 0

                -- A large displacement between adjacent samples is the same
                -- dash transition recorded by the stock Common helper. Keep
                -- both endpoints and the tick for modules that consume it.
                if elapsed >= 0 and elapsed < 300 and moved > 140 then
                    history.DashFrom = history.pos:Copy()
                    history.DashTo = current:Copy()
                    history.DashTime = now
                end
            else
                history = {}
                EnemyPositionHistory[handle] = history
            end

            -- While the native dash flag is active, use the navigation end
            -- point as LS does. Sampling alone can miss a short dash between
            -- two LagFree refreshes.
            if enemy.isDashing then
                local ok, dashTo = pcall(function() return enemy:GetWayPoint() end)
                if ok and dashTo and dashTo.x then
                    if not history.DashTime or now - history.DashTime >= 300 then
                        history.DashFrom = current:Copy()
                    end
                    history.DashTo = dashTo:Copy()
                    history.DashTime = now
                end
            end

            history.time = now
            history.pos = current
        end
    end

    return EnemyPositionHistory
end

-- Return the start and end position of an enemy dash that is closing the gap
-- to referencePosition. FH modules (including Caitlyn) use the first return
-- value as a truthy anti-gap trigger and the second as the dash destination.
function EnemyGapClosing(referencePosition, maxRange)
    referencePosition = referencePosition or Player.position
    maxRange = maxRange or 800

    local now = Game.GetTickCount()
    local closestFrom, closestTo
    local closestDistance = math.huge

    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy:IsValid() and enemy.isAlive and enemy:IsValidTarget()
            and enemy.team ~= Player.team and Common.GetDistance2(enemy.position, referencePosition) < maxRange then
            local dashFrom
            local dashTo

            if enemy.isDashing then
                local ok, wayPoint = pcall(function() return enemy:GetWayPoint() end)
                if ok and wayPoint and wayPoint.x then
                    dashFrom = enemy.position
                    dashTo = wayPoint
                end
            end

            if not dashTo then
                local history = EnemyPositionHistory[enemy.handle]
                if history and history.DashTime and now - history.DashTime >= 0
                    and now - history.DashTime < 300 then
                    dashFrom = history.DashFrom
                    dashTo = history.DashTo
                end
            end

            if dashFrom and dashTo then
                local fromDistance = Common.GetDistance2(dashFrom, referencePosition)
                local toDistance = Common.GetDistance2(dashTo, referencePosition)

                -- LS only treats it as a gap close when the endpoint is both
                -- nearer than the current position and inside the danger area.
                if toDistance < fromDistance and toDistance < 300 and toDistance < closestDistance then
                    closestFrom = dashFrom:Copy()
                    closestTo = dashTo:Copy()
                    closestDistance = toDistance
                end
            end
        end
    end

    return closestFrom, closestTo
end

function ClosestEnemy()
    local closestEnemy
    for i, enemy in ObjectManager.enemyHeroes:pairs() do
        if closestEnemy == nil or (closestEnemy and Common.ValidTarget2(closestEnemy) and Common.GetDistance2(Player.position, closestEnemy.position) > Common.GetDistance2(Player.position, enemy.position)) then
            closestEnemy = enemy
        end
    end
    return closestEnemy
end

function LineHitCheck(startPos, endPos, width, hitObject, edge)
    if edge == nil then edge = true end
    local x1 = startPos.x
    local x2 = endPos.x
    local y1 = startPos.z
    local y2 = endPos.z
    local px = hitObject.x
    local py = hitObject.z
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / length, dy / length
    local posOnLine = dx * (px - x1) + dy * (py - y1)
    if posOnLine < 0 and edge then
        -- first end point is closest
        dx, dy = px - x1, py - y1
        return math.sqrt(dx * dx + dy * dy) < width
    elseif posOnLine > length and edge then
        -- second end point is closest
        dx, dy = px - x2, py - y2
        return math.sqrt(dx * dx + dy * dy) < width
    else
        -- point is closest to some part in the middle of the line
        if (math.abs(dy * (px - x1) - dx * (py - y1))) < width then
            return true
        end
    end
    return false
end

function IsFleeing(target, pos)
    pos = pos or Player.position
    if target then
        local tarpos = MovementPrediction.GetPrediction(target, 0.5).unitPosition
        if tarpos then
            if Common.GetDistance2(tarpos, pos) > Common.GetDistance2(target.position, pos) then
                return true
            end
        end
    end
    return false
end

local KayleRbuffHash = Game.fnvhash("judicatorintervention")
local ZileanRbuffHash = Game.fnvhash("chronoshift")
local TryndamereRbuffHash = Game.fnvhash("undyingrage")
local KindredRbuffHash = Game.fnvhash("KindredRNoDeathBuff")
local FioraWbuffHash = Game.fnvhash("FioraW")

function IsUnitImmune(unit)
    if unit.charName == "Fiora" and unit:FindBuff(FioraWbuffHash) then return true end
    if EnemiesInGame["Kayle"] and unit:FindBuff(KayleRbuffHash) then return true end
    if EnemiesInGame["Zilean"] and unit:FindBuff(ZileanRbuffHash) then return true end
    if EnemiesInGame["Kindred"] and unit.hpPercent <= 10 and unit:FindBuff(KindredRbuffHash) then return true end
    if unit.charName == "Tryndamere" and unit.hpPercent <= 10 and unit:FindBuff(TryndamereRbuffHash) then return true end
    return false
end

function IsInsideEnemyFountain(position)
    return TurretTracker.IsInsideEnemyFountain(position:To2D()).IsInsideRange
end

local enemyTurretAggroHeroes, enemyTurretAggroOthers = {}, {}
Callback.Bind(CallbackType.OnSpellAnimationStart, function(sender, args)
    if not sender or not sender:IsValid() or not args.spell or not args.target or not sender.team == Team.Enemy or not sender.type == ObjectType.AITurretClient then return end
    if args.target.type == ObjectType.AIHeroClient then
        enemyTurretAggroHeroes[sender.networkId] = { networkIdTarget = args.target.networkId, aggroStartTime = Game.GetTime() }
    else
        enemyTurretAggroOthers[sender.networkId] = { networkIdTarget = args.target.networkId, aggroStartTime = Game.GetTime() }
    end
end)

local allyTurretAggroHeroes = {}
Callback.Bind(CallbackType.OnSpellAnimationStart, function(sender, args)
    if not sender or not sender:IsValid() or not args.spell or not args.target or not sender.team == Team.Ally or not sender.type == ObjectType.AITurretClient then return end
    if args.target.type == ObjectType.AIHeroClient then
        allyTurretAggroHeroes[sender.networkId] = {
            allyTurret = sender.networkId,
            allyTurretPosition = sender.position,
            networkIdTarget = args.target.networkId,
            aggroStartTime = Game.GetTime(),
            aggroEndTime = Game.GetTime() + 1.2
        }
    end
end)

function GetAllyTurretAggroHeroInfo(turret)
    if not turret or not allyTurretAggroHeroes[turret.networkId] then return {} end
    return allyTurretAggroHeroes[turret.networkId]
end

function GetTurretAggroHeroesInfo(turret)
    if not turret or not enemyTurretAggroHeroes[turret.networkId] then return {} end
    return enemyTurretAggroHeroes[turret.networkId]
end

function GetTurretAggroOthersInfo(turret)
    if not turret or not enemyTurretAggroOthers[turret.networkId] then return {} end
    return enemyTurretAggroOthers[turret.networkId]
end

function GetEnemyTurretIfCanShoot(position)
    local turretAttackDistance = 900
    local pos = position or Player.position
    for _, entity in ObjectManager.enemyTurrets:pairs() do
        if entity and entity:IsValid() and Common.GetDistance2(pos, entity.position) < turretAttackDistance then
            return entity
        end
    end
end

-- ITEMS (shared with LuaCommon/utility/utility.lua)
function CastAllItems(target, skipTable, onlyLC)
    if Player.isDashing then return end

    -- Rocketbelt: dash / damage
    if skipTable == nil or skipTable[3152] == nil then
        if onlyLC == nil or onlyLC == false then
            local slot = 3152
            if Player:FindItem(slot) and Player:CanUseItem(slot) then
                local itemSlot = Player:FindItemSlot(slot)
                if itemSlot and Common.GetDistance2(target.position) < 800 then
                    -- local rocketbeltDamage = DamageLib.CalculateMagicalDamage(Player, target, 125 + Player.totalAbilityPower * .15)
                    if target.hpPercent < 40 then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:SetSkillshot(0.75, 400, 2000, SkillshotType.SkillshotLine, false,
                            CollisionFlag.CollidesWithNothing, HitChance.Medium, false)
                        local pred = itemSpell:GetPrediction(target)
                        if pred and pred.unitPosition and Common.GetDistance2(pred.unitPosition) < 1100 then
                            itemSpell:Cast(pred.unitPosition)
                        end
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Locket: shield
    if skipTable == nil or skipTable[3190] == nil then
        if onlyLC == nil or onlyLC == false then
            local slot = 3190
            if Player:FindItem(slot) and Player:CanUseItem(slot) then
                local itemSlot = Player:FindItemSlot(slot)
                if itemSlot and Player.position:CountEnemiesInRange(800) >= 1 then
                    -- Check incoming damage
                    if Player.hpPercent < 40 then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Randuin: AOE Slow
    if skipTable == nil or skipTable[3143] == nil then
        if onlyLC == nil or onlyLC == false then
            local slot = 3143
            if Player:FindItem(slot) and Player:CanUseItem(slot) then
                local itemSlot = Player:FindItemSlot(slot)
                if itemSlot then
                    if Player.position:CountEnemiesInRange(450) > 1 then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Redemption: AOE Heal
    if skipTable == nil or skipTable[3107] == nil then
        if onlyLC == nil or onlyLC == false then
            local slot = 3107
            if Player:FindItem(slot) and Player:CanUseItem(slot) then
                local itemSlot = Player:FindItemSlot(slot)
                if itemSlot then
                    for i, ally in ObjectManager.allyHeroes:pairs() do
                        if not ally.isMe and ally.isAlive then
                            if ally.position:CountEnemiesInRange(700) >= 2 and ally.hpPercent > 10 and ally.hpPercent < 75 and Common.GetDistance2(ally.position) < 5500 then
                                local itemSpell = SDKSpell.Create(itemSlot, 6000, DamageType.Physical)
                                itemSpell:Cast(ally.position)
                                itemSpell:Delete()
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- Stridebreaker: AOE Slow
    if skipTable == nil or skipTable[6631] == nil then
        if onlyLC == nil or onlyLC == false then
            local slot = 6631
            if Player:FindItem(slot) and Player:CanUseItem(slot) then
                local itemSlot = Player:FindItemSlot(slot)
                if itemSlot then
                    if Player.position:CountEnemiesInRange(450) > 0 then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Tiamat
    if skipTable == nil or skipTable[3077] == nil then
        local slot = 3077
        if Player:FindItem(slot) and Player:CanUseItem(slot) then
            local itemSlot = Player:FindItemSlot(slot)
            if itemSlot then
                if Player.position:CountEnemiesInRange(400) > 0 or (onlyLC and onlyLC == true and Common.GetDistance2(target.position) < 400) then
                    if Orbwalker.CanMove() and not Orbwalker.CanAttack() then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Hydra
    if skipTable == nil or skipTable[3074] == nil then
        local slot = 3074
        if Player:FindItem(slot) and Player:CanUseItem(slot) then
            local itemSlot = Player:FindItemSlot(slot)
            if itemSlot then
                if Player.position:CountEnemiesInRange(400) > 0 or (onlyLC and onlyLC == true and Common.GetDistance2(target.position) < 400) then
                    if Orbwalker.CanMove() and not Orbwalker.CanAttack() then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end

    -- Titanic
    if skipTable == nil or skipTable[3748] == nil then
        local slot = 3748
        if Player:FindItem(slot) and Player:CanUseItem(slot) then
            local itemSlot = Player:FindItemSlot(slot)
            if itemSlot then
                if (Player.position:CountEnemiesInRange(Player:GetAutoAttackRange(Player)) > 0 or (onlyLC and onlyLC == true and Common.GetDistance2(target.position) < Player:GetAutoAttackRange(Player))) and Orbwalker.CanMove() and not Orbwalker.CanAttack() then
                    local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                    itemSpell:Cast()
                    itemSpell:Delete()
                end
            end
        end
    end

    -- Profane
    if skipTable == nil or skipTable[6698] == nil then
        local slot = 6698
        if Player:FindItem(slot) and Player:CanUseItem(slot) then
            local itemSlot = Player:FindItemSlot(slot)
            if itemSlot then
                if Player.position:CountEnemiesInRange(400) > 0 or (onlyLC and onlyLC == true and Common.GetDistance2(target.position) < 400) then
                    if Orbwalker.CanMove() and not Orbwalker.CanAttack() then
                        local itemSpell = SDKSpell.Create(itemSlot, 4000, DamageType.Physical)
                        itemSpell:Cast()
                        itemSpell:Delete()
                    end
                end
            end
        end
    end
end

---- GET CURRENT PLAYER BUFFS
-- for i, v in Game.localPlayer.buffManager.buffs:pairs() do
--     if v.isValid then
--         print(v:GetName(), v.hash, v.leftTime, v.short, v.isPermanent, v.type)
--     end
-- end
-- Game.GetSelectedTarget()

local BansheesVeilbuffHash = Game.fnvhash("bansheesveil")
local EdgeOfNightbuffHash = Game.fnvhash("itemmagekillerveil")
local NocturneWbuffHash = Game.fnvhash("NocturneShroudofDarkness")
local SivirEbuffHash = Game.fnvhash("SivirE")

function IsUnitSpellImmune(unit)
    if unit:FindBuff(BansheesVeilbuffHash) then return true end
    if unit:FindBuff(EdgeOfNightbuffHash) then return true end
    if unit:FindBuff(NocturneWbuffHash) then return true end
    if unit:FindBuff(SivirEbuffHash) then return true end
    return false
end

-- get recall left time
local buffRecallHash = Game.fnvhash("recall")
local buffSuperRecallHash = Game.fnvhash("SuperRecall")

function GetRemainingRecallTime()
    local buffRecall = Player:FindBuff(buffRecallHash)
    if buffRecall then
        return buffRecall.leftTime
    end
    local buffSuperRecall = Player:FindBuff(buffSuperRecallHash)
    if buffSuperRecall then
        return buffSuperRecall.leftTime
    end
    return 0
end

-- Runes
local coupdegraceRune, laststandRune = false, false
for i, perkInfo in Player.avatarClient.perks:pairs() do
    if perkInfo.data.name == 'CoupDeGrace' then
        coupdegraceRune = true
    end
    if perkInfo.data.name == 'LastStand' then
        laststandRune = true
    end
    -- print(i, perkInfo.data.name)
end

function GetRuneDamageMod(enemy)
    if coupdegraceRune and enemy.hpPercent < 40 then
        return 1.08
    elseif laststandRune and Player.hpPercent < 60 then
        local missingHP = 100 - Player.hpPercent
        local laststandDamage = missingHP > 70 and 1.11 or missingHP > 60 and 1.09 or missingHP > 50 and 1.07 or missingHP > 40 and 1.05
        return laststandDamage
    else
        return 1
    end
end

end


_G.OM = ObjectManager

_G.Loaded = true
