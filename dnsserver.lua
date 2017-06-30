local version=1.0
local args={...}
local fs=require("filesystem")
local serial=require("serialization")
local component=require("component")
local computer=require("computer")
local modem=component.modem
local event=require("event")
local liste={}
local runing=false
local config={}
local net=require("network")
local me=""
modem.open(100)

function cleanOld(name, addr)
    for k, v in pairs(liste) do
        if v==addr and k~=name then
            liste[k]=nil
            liste.remove(k)
        end
    end
end

function register(name, addr)
    if liste[name]==nil or liste[name]~=addr then
        liste[name]=addr
        cleanOld(name, addr)
        save()
    end
end

function save()
    local file=io.open("/etc/dnsTable","w")
    file:write(serial.serialize(liste))
    file:close()
end

function loadConfig()
    local file=io.open("/etc/dns.cfg", "r")
    local text=file:read("*all")
    file:close()
    config=serial.unserialize(text)
end

function load()
    if fs.exists("/etc/dnsTable") then
        local file=io.open("/etc/dnsTable","r")
        local text=file:read("*all")
        file:close()
        liste={}
        liste=serial.unserialize(text)
    end
end

function dnsDrop()
    liste={}
    save()
end

function isRuning()
    if runing then
        computer.pushSignal("dnsServerRuning")
    end
    return runing
end

function getAddr(name)
    if name==config["dnsserver"] then
        return me
    else
        return liste[name]
    end
end

function get(name, addr)
    local res=getAddr(name)
    modem.send(addr, 100, "req", res, name)
end

function handler(event, me, from, port, distance, command, value)
    if port==100 then
        if command~=null then
            if command=="set" then
                register(value, from)
            elseif command=="req" then
                --ignore
            else
                get(command, from)
            end
        end
    end
end

function printTable()
    for k, v in pairs(liste) do
        print(k,v)
    end
end

function localGet(e,name, n)
    addr=getAddr(name)
    computer.pushSignal("dnsReq", addr, name)
end

function restart()
    stop()
    start()
end

function start()
    me=modem.address
    os.sleep(1)
    loadConfig()
    if not getServerState() then
        load()
        event.listen("modem_message", handler)
        event.listen("dnsServerStop", stop)
        event.listen("dnsServerPrintTable", printTable)
        event.listen("dnsServerStatus", isRuning)
        event.listen("dnsServerDrop", dnsDrop)
        event.listen("dnsGet", localGet)
        runing=true
        print("DNS-Server auf "..me.." gestartet.")
    else
        print("DNS-Server läuft bereits")
    end
end

function getServerState()
    computer.pushSignal("dnsServerStatus")
    local state=event.pull(1, "dnsServerRuning")
    if state~=nil then
        return true
    else
        return false
    end
end

function stop()
    runing=false
    event.ignore("modem_message", handler)
    event.ignore("dnsServerStop", stop)
    event.ignore("dnsServerPrintTable", printTable)
    event.ignore("dnsServerStatus", isRuning)
    event.ignore("dnsServerDrop", dnsDrop)
    event.ignore("dnsGet", localGet)
    save()
    list={}
    config={}
end

if args[1]~=null then
    if args[1]=="run" then
        start()
    elseif args[1]=="print" then
        computer.pushSignal("dnsServerPrintTable")
    elseif args[1]=="stop" then
        computer.pushSignal("dnsServerStop")
    elseif args[1]=="restart" then
        computer.pushSignal("dnsServerStop")
        start()
    elseif args[1]=="drop" then
        computer.pushSignal("dnsServerDrop")
    elseif args[1]=="status" then
        if getServerState() then
            print("DNS läuft")
        else
            print("DNS läuft nicht")
        end
    end
end