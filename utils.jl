export restoreModel!

function restoreModel!(M)
    for s in [:pars, :init, :spec]
        M.(s) = M.originalState[s]
    end
end
