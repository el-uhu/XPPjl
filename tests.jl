using Base.Test
using PyPlot
using XPP

custom_handler(r::Test.Success) = println("Success on $(r.expr)")
custom_handler(r::Test.Failure) = error("test failed: $(r.expr)")
custom_handler(r::Test.Error)   = rethrow(r)

Test.with_handler(custom_handler) do
    #Does the Module load properly?
    M = fromOdeFile("CaChannel.ode")
    loading_model = typeof(M) == XPP.Model
    @test loading_model

    #Can we run a simulation?
    runSimulation!(M, "test1")
    running_simulation = typeof(M.sims["test1"]) == XPP.SimulationData
    @test running_simulation


    #Are datasets from multiple simulations actually different?
    # ... there used to be problems with the way julia stores arrays!
    pars = [p for p in keys(M.pars)]
    selected_parameter = pars[rand(1:length(pars))]
    M.pars[selected_parameter] = M.pars[selected_parameter] * rand()
    runSimulation!(M, "test2")
    correct_storage_overall = M.sims["test1"] != M.sims["test2"]
    @test correct_storage_overall
    correct_storage_pars = M.sims["test1"].P[selected_parameter] != M.sims["test2"].P[selected_parameter]
    @test correct_storage_pars

    #Can we produce a plot?
    myPlot = plotModel(M, "test1")
    plot_model = myPlot != None
    @test plot_model
end
