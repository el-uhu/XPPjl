export Env, os
@doc doc"""
Custom type to store os-environment sensitive parameters and commands
"""->
type Env
    newline::String
    xppcall::String
    options::Array
end

if VERSION < v"0.4.0"
    using Docile
end


#set os-dependent variables
os = Dict()
os[:Linux] = Env("\n", "xppaut", ["-silent",  "-logfile",  "log.txt"])
os[:Windows] = Env("\r\n", "/xppall/xppaut", ["-silent",  "-logfile",  "log.txt"])
os[:Darwin] = Env("\n", "xppaut", ["-silent",  "-logfile",  "log.txt"])
