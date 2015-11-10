packages = [
    "PyCall",
    "PyPlot",
    "JSON",
    "Docile",
    "ODE"
    ]

Pkg.init()
Pkg.update()

for package in packages
    Pkg.add(package)
end
