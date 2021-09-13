# code to use RCall for climate GAMS

using RCall, CSV, DataFrames
using GeoStats
using Plots; gr(size=(700,400))
using Distributions

#### load data ####
data = CSV.read("data/output/data_for_gam.csv", DataFrame)
filter!(
    row -> (row.year > 1990 && row.year < 2000) && (row.season == "dry"), data
)

# add some noise to coords
distr = Normal()
noise_1 = rand(distr, nrow(data))
noise_2 = rand(distr, nrow(data))

data.x = data.x .+ noise_1
data.y = data.y .+ noise_2

# load raster data
R"
library(mgcv)
library(raster)
stack = raster::stack('data/output/raster_gam_stack.tif')
"

#### run gam and predict on coast and elevation raster ####
R"
mod = gam(
    formula = tmean_mean ~ s(elev), data = $data
)
# not really necessary for now
pred = predict(stack[[c('elev')]], mod, type = 'response')
"
R"x11();plot(pred, col = viridis::turbo(30))"
#### get data frame of coordinates for predictions ####
dgrf = copy(data)
dgrf[!, :resid] = rcopy(R"resid(mod)")

# now georeference for geostats
dgrf = georef(dgrf, (:x, :y))
grd = CartesianGrid((30, 30), (75., 9.), (0.2, 0.2))
plot(grd)

problem = EstimationProblem(
    dgrf, grd, :resid
)

solver = Kriging(
    :resid => (variogram=GaussianVariogram(
        # sill = 0.15, 
        range=10.0,
        # nugget = 0.01
        ),
    )
)

solution = solve(problem, solver)

μ, σ² = solution[:resid]

plot(solution)
