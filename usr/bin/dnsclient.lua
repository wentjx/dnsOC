local version = 1.03
local args = { ... }
local component = require("component")
local computer = require("computer")
local serial = require("serialization")
local event = require("event")
local modem = component.modem
local liste = {}
local config = {}
local found = false
local runing = false

function getTicks()
    return ((os.time() * 1000) / 60 / 60) - 6000
end

function getServer()
    local t1 = getTicks()
    local srun = true
    modem.broadcast(config.port, config["dnsserver"])
    local _, _, _, port, _, command, addr, rname
    while srun and not found do
        local t2 = getTicks()
        if t2 > t1 + 120 or t2 < t1 - 99 then
            srun = false
        end
        _, _, _, port, _, command, addr, rname = event.pull(1, "modem_message")
        if port == config.port and command == "req" and rname == config["dnsserver"] then
            found = true
        end
    end
    if found then
        liste[config["dnsserver"]] = addr
    else
        modem.broadcast(config.announceport, "needDns")
    end
end

function register()
    if found then
        print(config["dnsserver"], config.port, config["computername"])
        modem.send(liste[config["dnsserver"]], config.port, "set", config["computername"])
    end
end

function getingAnnonce(_, _, from, port, _, command, value)
    if port == config.announceport then
        if command == "dnsAnnounce" and not found then
            liste[config["dnsserver"]] = from
            found = true
            register()
        end
    end
end

function loadConfig()
    local file = io.open("/etc/dns.cfg")
    local text = file:read("*all")
    file:close()
    config = serial.unserialize(text)
end

function request(name)
    if not found then
        getServer()
        if not found then
            print("ERROR: No DNS-Server found!")
            return ""
        else
            register()
        end
    end
    local t1 = getTicks()
    local srun = true
    local found = false
    modem.send(liste[config["dnsserver"]], config.port, name)
    local _, _, _, port, _, command, addr, rname
    while srun and not found do
        local t2 = getTicks()
        if t2 > t1 + 80 or t2 < t1 - 79 then
            srun = false
        end
        _, _, _, port, _, command, addr, rname = event.pull("modem_message")
        if port == config.port and command == "req" and rname == name then
            found = true
        end
    end
    return addr
end

function ns(name, n)
    if n or liste[name] == null or liste[name] == "" then
        return request(name)
    else
        return liste[name]
    end
end

function nsDaemon(_, name, n)
    computer.pushSignal("dnsReq", ns(name, n), name)
end

function init()
    loadConfig()
    if not config["server"] then
        modem.open(config.port)
        if config.announces then
            modem.open(config.announceport)
            event.listen("modem_message", getingAnnonce)
        end
        event.listen("dnsClientStop", stop)
        event.listen("dnsRegister", register)
        event.listen("dnsClientStatus", getState)
        event.ignore("dnsClientRestart", restart)
        runing=true
        getServer()
        if found then
            register()
            event.listen("dnsGet", nsDaemon)
        end
    else
        print("It is a server already")
    end
end

function getState()
    if runing then
        computer.pushSignal("dnsClientRuning")
    end
    return runing
end

function isRuning()
    computer.pushSignal("dnsClientStatus")
    local state = event.pull(1, "dnsServerRuning")
    if state ~= nil then
        return true
    else
        return false
    end
end

function start()
    if not isRuning() then
        init()
    else
        print("Client runing already")
    end
end

function restart()
    stop()
    start()
end

function stop()
    modem.close(config.port)
    event.ignore("dnsGet", nsDaemon)
    event.ignore("dnsClientStop", stop)
    event.ignore("dnsClientRestart", restart)
    event.ignore("dnsClientStatus", getState)
    if config.announces then
        modem.close(config.announceport)
        event.ignore("modem_message", getingAnnonce)
    end
    runing=false
    liste = {}
    config = {}
end

if args[1] ~= nil then
    if args[1] == "start" then
        start()
    elseif args[1] == "stop" then
        computer.pushSignal("dnsClientStop")
    elseif args[1] == "restart" then
        computer.pushSignal("dnsClientRestart")
    elseif args[1] == "status" then
        if isRuning() then
           print("client runing and binded on "..liste[config["dnsserver"]])
        else
           print("client not runing")
        end
    elseif args[1] == "register" then
        computer.pushSignal("dnsRegister")
    end
end