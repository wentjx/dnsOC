local version=1.0
local args={...}
local component=require("component")
local computer=require("computer")
local serial=require("serialization")
local event=require("event")
local fs=require("filesystem")
local modem=component.modem
modem.open(100)
local liste={}
local config
local found=false
function getTicks()
    return ((os.time() * 1000) / 60 /60) - 6000
end

function getServer()
    local t1=getTicks()
    local srun=true
    modem.broadcast(100, config["dnsserver"])
    while srun and not found do
        local t2=getTicks()
        if t2>t1+120 or t2<t1-99 then
            srun=false
        end
        _,_,_, port, _, command, addr, rname=event.pull(1,"modem_message")
        if port==100 and command=="req" and rname==config["dnsserver"] then
            found=true
        end
    end
    if found then
        liste[config["dnsserver"]]=addr
        print("DNS:"..addr)
    else
        print("Kein DNS im Netz gefunden")
    end
end

function register()
    modem.send(liste[config["dnsserver"]], 100, "set", config["computername"])
end

function loadConfig()
    local file=io.open("/etc/dns.cfg")
    local text=file:read("*all")
    file:close()
    config=serial.unserialize(text)
end

function request(name)
    local t1=getTicks()
    local srun=true
    local found=false
    modem.send(liste[config["dnsserver"]], 100, name)
    while srun and not found do
        local t2=getTicks()
        if t2>t1+80 or t2<t1-79 then
            srun=false
        end
        _, _, _, port, _, command, addr, rname=event.pull("modem_message")
        if port==100 and command=="req" and rname==name then
            found=true
        end
    end
    return addr
end

function ns(name, n)
    if n or liste[name]==null or liste[name]=="" then
        return request(name)
    else
        return liste[name]
    end
end

function nsDaemon(event, name, n)
    computer.pushSignal("dnsReq", ns(name, n), name)
end

function init()
    os.sleep(1)
    loadConfig()
    if not config["server"] then
        getServer()
        if found then
            register()
            event.listen("dnsGet", nsDaemon)
        end
    end
end

function start()
    init()
end

if args[1]~=nil then
    if args[1]=="run" then
        start()
    end
end