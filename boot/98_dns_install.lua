local fs=require("filesystem")
fs.copy("/home/.shrc", "/home/.shrc.bck")
dat = io.open("/home/.shrc", "a")
dat:write("\n/usr/bin/dnsinstall")
dat:close()

