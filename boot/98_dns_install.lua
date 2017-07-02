local fs=require("filesystem")
fs.copy("/home/.shrc", "/home/.srhc.bck")
dat = io.open("/home/.shrc", "a")
dat:write("/usr/bin/dnsinstall")
dat:close()

