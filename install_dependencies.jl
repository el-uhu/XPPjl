packages = [
    "PyPlot",
    "JSON",
    "Docile"
    ]

Pkg.init()
Pkg.update()

for package in packages
    Pkg.add(package)
end
