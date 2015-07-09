using PyPlot
export plotModel


@doc doc"""
High-level plotting routine for model simulations
"""->
function plotModel(M, simName; t = "t", pars = false, vars = false, xlim = false, ylim =false, colors = false, linewidth = 2, fig = true, alpha = 1)
    if fig == true
        figure()
    end
    if pars
        ax1 = subplot2grid([4,1], [0,0], 3, 1)
        plotModel_core(ax1, M, simName; t = t, vars = vars, xlim = xlim, ylim = ylim, colors = colors, linewidth = linewidth, alpha = alpha)
        ax2 = subplot2grid([4,1], [3,0], 1, 1)
        plotPars(ax2, M, simName)
    else
        ax = subplot(111)
        plotModel_core(ax, M, simName; t = t, vars = vars, xlim = xlim, ylim = ylim, colors = colors, linewidth = linewidth, alpha = alpha)
    end
    if fig == true
        suptitle(simName)
    end
end

function plotPars(subplot, M, simName)
    P = M.sims[simName].P
    pars = [P[p] for p in keys(P)]
    names = [p for p in keys(P)]
    ixs = [rand() for p in pars]
    scatter(pars, ixs, marker = "o",  color = "k", alpha = 0.5, label = names)
    subplot[:set_xscale]("log")
    subplot[:set_xlim]([0.0001, 10000])
    for i in [1:length(pars)]
        if pars[i] != 0
            annotate(names[i], xy = (pars[i]*1.2, ixs[i]))
        end
    end
    subplot[:set_yticks]([])
    grid(b = true)
    grid(b = true, which = "minor", alpha = 0.2)
    # subplot[:set_yticklabels](names)
end

function plotModel_core(subplot, M, simName; t = "t", vars = false, xlim = false, ylim =false, colors = false, linewidth = 2, alpha = 1)
    D = M.sims[simName].D
    if vars == false
        vars = M.vars[2:end]
    end
    for v in vars
        if colors == false
            plot(D[t], D[v], linewidth = linewidth, alpha = alpha)
        else
            plot(D[t], D[v], color = colors[v], linewidth = linewidth, alpha = alpha)
        end
    end
    xlabel("t (min)")
    ylabel("")
    if xlim != false
        subplot[:set_xlim](xlim)
    end
    if ylim != false
        subplot[:set_ylim](ylim)
    end
end
