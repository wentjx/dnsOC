local packagename="dnsocclient"
local shell=require("shell")
local fs=require("filesystem")
if fs.exists("/usr/bin/oppm.lua") then
    fs.rename("/etc/oppm.cfg", "/etc/oppm.cfg.bck")
else
    shell.execute("pastebin get aaZTqY9T /etc/oppm.cfg")
end
shell.execute("pastebin get aaZTqY9T /etc/oppm.cfg")
shell.execute("oppm install "..packagename)
fs.remove("/etc/oppm.cfg")
fs.rename("/etc/oppm.cfg.bck", "/etc/oppm.cfg")
shell.execute("/usr/bin/dnsinstall")
