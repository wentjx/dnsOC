local computer=require("computer")
local event=require("event")
local dns={}

dns.version=1.0

function dns.getTicks()
    return ((os.time() * 1000) / 60 /60) - 6000
end

function dns.ns(name, n)
    local t1=getTicks()
    local t2=getTicks()
    local k=true
    local f=false
    local addr=""
    computer.pushSignal("dnsGet", name, n)
    while k and not f do
        t2=os.getTicks()
        if t1+120<t2 or t2<t1-99 then
            k=false
        end
        e, addr, rname= event.pull(2, "dnsReq")
        if e~=nil and rname==name then
            f=true
        end
    end
    if f then
        return addr
    else
        return ""
    end
end

return dns