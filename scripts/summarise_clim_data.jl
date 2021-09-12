# code to explore climate data
# borrows liberally from R using RCall

using RCall, CSV, DataFrames
using Dates
using StatsBase, Statistics
using Gadfly, Cairo

# lead files in directory
files = readdir("data/raw/iitg-climate",  join = true)
files_ = readdir("data/raw/iitg-climate",  join = false)

# make date range
dates = collect(
    Date(1870, 1, 1):Day(1):Date(2018, 12, 31)
)

# function to operate on files and files_
function process_file(file, file_)
    # read file
    df = CSV.read(
        file,
        header = ["ppt", "tmax", "tmin", "wind"], 
        delim = " ", DataFrame 
    )
    transform!(df, [:tmin, :tmax] => 
        ByRow((tmin, tmax) -> (tmin + tmax) / 2) => :tmean)
    # get coordinates from filename
    coord = eachmatch(r"\d+.\d+", file_)
    coord = collect(coord)
    x = coord[2].match
    y = coord[1].match
    # assign coordinates
    df[!, :x] .= x
    df[!, :y] .= y
    # asign month and year
    df[!, :month] = Dates.month.(dates)
    df[!, :year] = Dates.year.(dates)

    # get month-yearly sum mean and sd for ppt and temp
    df_summary = combine(
        # df,
        groupby(df, [:month, :year, :x, :y]),
        :ppt => sum,
        :tmean => mean,
        :tmean => std
    )
    df_summary
end

# apply function to data
data = process_file.(files, files_)
data = reduce(vcat, data)

# save
CSV.write("data/output/data_monthly_climate.csv", data)
