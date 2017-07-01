local term = require("term")
local file = require("filesystem")
local serial = require("serialization")
local autostart = { "dnsclient" }
local process = require("process")
local shell = require("shell")

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
            line["enabled"].insert(daemon)
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

function copyFiles()
    file.remove("/lib/dns.lua")
    file.remove("/etc/rc.d/dnsclient.lua")
    file.remove("/etc/dns.cfg")
    shell.execute("pastebin get 3ZWNnPKZ /etc/rc.d/dnsclient.lua")
    shell.execute("pastebin get avL7Zwxt /lib/dns.lua")
    shell.execute("pastebin get UGpiAYFp /etc/dns.cfg")
end

function namePC()
    local dat = io.open("/etc/dns.cfg", "r")
    local text = dat:read("*all")
    dat:close()
    local config = serial.unserialize(text)
    config["dnsserver"] = "ServerDNS1"
    if not config["server"] then
        -- term.clear()
        term.write("Computernamen bitte eingeben: ")
        config["computername"] = io.read()
    else
        config["computername"] = config["dnsserver"]
    end
    dat = io.open("/etc/dns.cfg", "w")
    dat:write(serial.serialize(config))
    dat:close()
end

function main()
    copyFiles()
    namePC()
    configRC()
end

main()