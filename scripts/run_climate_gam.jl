# code to use RCall for climate GAMS

using RCall, CSV, DataFrames
using GeoStats
using Plots; gr(size=(700,400))

# load data
data = CSV.read("data/output/data_for_gam.csv", DataFrame)
filter!(
    row -> row.year == 2000, data
)
dgrf = georef(data, (:x, :y))
grd = CartesianGrid((30, 30), (75., 9.), (0.2, 0.2))
plot(grd)

problem = EstimationProblem(
    dgrf, grd, :ppt_sum
)

solver = Kriging(
    :ppt_sum => (variogram=GaussianVariogram(range=10.0), drifts=[x -> 1 + x[2], x -> 2x[2]]
    )
)

solution = solve(problem, solver)

μ, σ² = solution[:ppt_sum]

plot(solution)