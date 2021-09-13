# code to prepare GAM data

using RCall, CSV, DataFrames

# load summary data and select unique coordinates
data = CSV.read("data/output/data_monthly_climate.csv", DataFrame)
filter!([:x, :y] => (x, y) -> y > 9.5 && y < 12 && x > 76 && x < 79, data)
coords = unique(data, [:x, :y])
select!(coords, [:x, :y])

# read elevation data
R"
library(terra)
library(sf)
library(ggplot2)
"
#### get elevation ####
R"
coord_sf = sf::st_as_sf($coords, coords = c('x', 'y'), crs = 4326)
ext = sf::st_bbox(coord_sf) |> 
    sf::st_as_sfc() |> 
    sf::st_transform(32643) |>
    sf::st_buffer(25000) |>
    sf::st_transform(4326)
elevation = terra::rast('data/spatial/Elevation/alt')
terra::crs(elevation)
elevation_hills = terra::crop(elevation, as(ext, 'Spatial'))
terra::writeRaster(elevation_hills, 'data/spatial/raster_elevation.tif',
    overwrite = TRUE)
"
# extract points
coord_elev = R"terra::extract(elevation, sf::st_coordinates(coord_sf))"
coord_elev = rcopy(coord_elev)
# add elevation to coords
coords[!, :elev] = coord_elev.alt

#### get distance to coast ####
R"
coast = sf::st_read('data/spatial/India/India_Boundary.shp')
coast = sf::st_cast(coast, 'MULTILINESTRING')
# plot(coast)
dist_coast = sf::st_distance(coord_sf, coast) / 1000
"
coords[!, :coast] = rcopy(R"as.vector(dist_coast)")

#### add elev and dist coast to data ####
data = leftjoin(data, coords, on = [:x, :y])

#### assign interval and season ####
bin_year = function (x)
    round( x / 5) * 5
end

get_season = function (x)
    (x > 5 && x < 12) ? "rainy" : "dry"
end

# assign manually because julia is stupidly difficult
data.bin_year = bin_year.(data.year)
data.season = get_season.(data.month)

# save data
CSV.write("data/output/data_for_gam.csv", data)
