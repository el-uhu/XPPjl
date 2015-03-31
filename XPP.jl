module XPP

if VERSION < v"0.4.0"
    using Docile
end

include("os.jl")
include("typedefs.jl")
include("parse.jl")
include("run.jl")
include("io.jl")
include("plot.jl")

end
