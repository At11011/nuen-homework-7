using DataFrames
using DelimitedFiles

# Data processing
function load_data(data_dir::String)::Dict
    paths = Dict(
    ("Lead Gamma Attenuation"=>"lead_attenuation.txt"),
    ("Tissue Gamma Attenuation"=>"tissue_attenuation.txt"),
    ("Iron Beta Stopping"=>"beta_stopping_iron.txt"),
    ("Iron Gamma Attenuation"=>"iron_attenuation.txt"),
    ("Air Gamma Attenuation"=>"air_attenuation.txt")
    )

    data_sets = Dict()
    for (set_name, path) in zip(keys(paths), values(paths))
        data, header = readdlm(joinpath(data_dir, path), ',', header=true)
        df = DataFrame(data, vec(header))
        for (name, data) in zip(names(df), eachcol(df))
            if name == "Energy"
                df[!, name] = data * u"MeV"
            elseif name == "Mass" || name == "En" 
                df[!, name] = data * u"cm^2/g"
            elseif name == "Collision" || name == "Radiative" || name == "Total" 
                df[!, name] = data * u"MeV*cm^2/g" 
            elseif name == "CSDA"
                df[!, name] = data * u"g/cm^2" 
            end
        end
        data_sets[set_name] = df
    end

    return data_sets
end
