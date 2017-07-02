local version="1.03"
local fs=require("filesystem")
local serial = require("serialization")
local term=require("term")
local config={}
local newconfig={}
local autostart = { "dnsservice" }
local server=false

function addeProgs(line)
    for _, daemon in pairs(autostart) do
        local found = false
        local i = 1
        last = i
        for _, value in pairs(line["enabled"]) do
            if value == daemon then
                found = true
            end
            i = i + 1
            last = i
        end
        if not found then
            line["enabled"][last](daemon)
        end
    end
    return line
end

function configRC()
    lines = {}
    local line = ""
    local i = 1
    local dat = io.open("/etc/rc.cfg", "r")
    local newtext
    local last = i
    local last_line
    repeat
        local c = dat:read(1)
        if c == "\n" then
            lines[i] = line
            i = i + 1
            line = ""
            last = i
        end
        if c ~= nil then
            line = line .. c
        end
        last_line = line
    until not c
    if string.len(last_line) > 1 then
        lines[last + 1] = line
    end
    dat:close()

    for _, value in pairs(lines) do
        local l = serial.unserialize("{" .. value .. "}")
        if l ~= nil and l["enabled"] ~= nil then
            l = addeProgs(l)
            value = serial.serialize(l)
            value = string.sub(value, 2, #value - 1)
        end
        newtext = newtext .. value .. "\n"
    end
    dat = io.open("/etc/rc.cfg", "w")
    dat:write(newtext)
    dat:close()
end


if fs.exists("/etc/dns.cfg") then
    local file = io.open("/etc/dns.cfg")
    local text = file:read("*all")
    file:close()
    config = serial.unserialize(text)
end
if fs.exists("/etc/hostname") then
    local file = io.open("/etc/dns.cfg")
    newconfig.computername = file:read("*all")
    file:close()
else
    newconfig.computername=config.computername
    while  newconfig.computername==nil or newconfig.computername=="" do
      term.clear()
      term.write("Computername:")
      newconfig.computername=io.read()
      newconfig.computername=newconfig.computername:gmatch("%S+")[1]
    end
end
if config and config.dnsserver then
    newconfig.dnsserver=config.dnsserver
else
    newconfig.dnsserver="ServerDNS1"
end
if config and config.port then

else
    newconfig.port=357
end
newconfig.server=server
newconfig.version=version
if config and config.announces then
    newconfig.announces=config.announces
else
    newconfig.announces=true
end
if config and config.announceport then
    newconfig.announceport=config.announceport
else
    newconfig.announceport=358
end
local file = io.open("/etc/hostname", "w")
file:write(newconfig.computername)
file:close()
local file = io.open("/etc/dns.cfg", "w")
file:write(serial.serialize(newconfig))
file:close()
configRC()

