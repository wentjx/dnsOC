local file=require("filesystem")
local serial=require("serialization")
local autostart= {"dnsserver"}
local shell=require("shell")

function addeProgs(line)
    for _, daemon in pairs(autostart) do
        local found=false
        local i=1
        last=i
        for key, value in pairs(line["enabled"]) do
            if value=="dnsclient" then
                line["enabled"][key]=nil
            else
                if value==daemon then
                    found=true
                end
            end
            i=i+1
            last=i
        end
        if not found then
            line["enabled"].insert(daemon)
        end
    end
    return line
end

function configRC()
    lines={}
    local line=""
    local i=1
    local dat=io.open("/etc/rc.cfg", "r")
    local newtext
    local last_line=""
    local last=1
    repeat
        local c=dat:read(1)
        if c=="\n" then
            lines[i]=line
            i=i+1
            line=""
            last=i
        end
        if c~=nil then
            line=line .. c
        end
        last_line=line
    until not c
    if string.len(last_line)>1 then
        lines[last+1]=line
    end
    dat:close()
    for key, value in pairs(lines) do
        local l=serial.unserialize("{"..value.."}")
        if l~=nil and  l["enabled"]~=nil then
            l=addeProgs(l)
            value=serial.serialize(l)
            value=string.sub(value, 2, #value-1)
        end
        newtext=newtext .. value .. "\n"
    end
    dat=io.open("/etc/rc.cfg", "w")
    dat:write(newtext)
    dat:close()
end

function copyFiles()
    file.remove("/lib/dns.lua")
    file.remove("/etc/rc.d/dnsclient.lua")
    file.remove("/etc/dns.cfg")
    file.remove("/etc/rc.d/dnsserver.lua")
    file.remove("/etc/dnsTable")
    shell.execute("pastebin get hsHnwJvE /etc/rc.d/dnsserver.lua")
    shell.execute("pastebin get avL7Zwxt /lib/dns.lua")
    shell.execute("pastebin get UGpiAYFp /etc/dns.cfg")
end

function namePC()
    local dat=io.open("/etc/dns.cfg","r")
    local text=dat:read("*all")
    dat:close()
    local config=serial.unserialize(text)
    config["dnsserver"]="ServerDNS1"
    config["computername"]="ServerDNS1"
    config["server"]=true
    dat=io.open("/etc/dns.cfg","w")
    dat:write(serial.serialize(config))
    dat:close()
end

copyFiles()
namePC()
configRC()