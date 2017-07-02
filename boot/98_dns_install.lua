local rs=require("filesystem")
filesystem.copy("/home/.shrc", "/home/.srhc.bck")
dat = io.open("/home/.shrc", "a")
dat:write("/usr/bin/dnsinstall")
dat:close()

