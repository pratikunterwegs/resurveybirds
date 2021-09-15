# code to use RCall for climate GAMS

using RCall, CSV, DataFrames
using GeoStats
using Plots; gr(size=(700,400))
using Distributions

#### load data ####
data = CSV.read("data/output/data_for_gam.csv", DataFrame)
filter!(
    row -> (row.year >= 1870 && row.year <= 1900) && (row.season == "dry"), data
)

# rescale function
rescale = function (x, min, max)
    (x - min) / (max - min)
end

# add some noise to coords
distr = Normal(0., 0.02)
noise_1 = rand(distr, nrow(data))
noise_2 = rand(distr, nrow(data))

data.x = data.x .+ noise_1
data.y = data.y .+ noise_2

# add lat
data.lat = data.y

# load raster data
R"
library(mgcv)
library(raster)
stack = raster::stack('data/output/raster_gam_stack.tif')
values(stack[['coast']]) = values(stack[['coast']]) / 1000
"

#### run gam and predict on coast and elevation raster ####
R"
mod = gam(
    formula = t_mean ~ s(elev, k = 4) + s(coast, lat, k = 5), data = $data
)
plot(mod)
"

R"pred = predict(stack[[c('elev', 'coast', 'lat')]], mod)"

# plot gam
R"
plot(pred, col = viridis::plasma(30, direction = 1), 
    main = 'GAM temp, 1870 -- 1900')
dev.capture('figures/fig_gam_temp.png', png)
"

#### get data frame of coordinates for predictions ####
dgrf = copy(data)
dgrf[!, :resid] = rcopy(R"resid(mod)")

# now georeference for geostats
dgrf = georef(dgrf, (:x, :y))
grd = CartesianGrid((50, 50), (76., 9.), (0.025, 0.025))

plot(grd)

problem = EstimationProblem(
    dgrf, grd, :resid
)

solver = Kriging(
    :resid => (variogram=GaussianVariogram(
        sill = 0.15, 
        range = 1.0,
        nugget = 0.01
        ),
    )
)

solution = solve(problem, solver)

μ, σ² = solution[:resid]

plot(solution)
