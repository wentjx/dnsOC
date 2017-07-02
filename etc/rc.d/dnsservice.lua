local shell = require("shell")
function start()
    local file = io.open("/etc/dns.cfg")
    local text = file:read("*all")
    file:close()
    config = serial.unserialize(text)
    if config.server then
        shell.execute("dnsserver start")
    else
        shell.execute("dnsclient start")
    end
end