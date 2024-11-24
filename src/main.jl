using Unitful
using Interpolations
using DataFrames
using CSV

include("co_60_shielding.jl")
include("source_characterization.jl")

act = 3000u"37GBq" # Activity of the source

source_characteristics(act)
data_interpolations = create_interpolations()
source_casing(data_interpolations["Iron Beta Stopping"])
lead_shielding(data_interpolations)
