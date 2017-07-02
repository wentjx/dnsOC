local packagename="dnsocclient"
local shell=require("shell")
local fs=require("filesystem")
fs.rename("/etc/oppm.cfg", "/etc/oppm.cfg.bck")
shell.exucute("pastebin get aaZTqY9T /etc/oppm.cfg")
shell.exucute("oppm install "..packagename)
fs.remove("/etc/oppm.cfg")
fs.rename("/etc/oppm.cfg.bck", "/etc/oppm.cfg")
shell.exucute("/usr/bin/dnsinstall")
