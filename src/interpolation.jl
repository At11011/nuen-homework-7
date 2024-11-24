function create_buildup_interpolation_function(filepath::String)
    df = CSV.read(filepath, DataFrame, delim=',', skipto=2, header=[:MeV, :ux, :B])
    df.MeV = df.MeV * 1u"MeV"

    MeV_values = sort(unique(df.MeV))
    ux_values = sort(unique(df.ux))

    B_matrix = zeros(length(MeV_values), length(ux_values))

    for row in eachrow(df)
        i = findfirst(==(row.MeV), MeV_values)
        j = findfirst(==(row.ux), ux_values)
        B_matrix[i, j] = row.B
    end

    itp = interpolate((MeV_values, ux_values), B_matrix,
                     Gridded(Linear()))

    return (MeV, ux) -> itp(MeV, ux), df
end

function create_reponse_interpolation_function(filepath::String)
    df = CSV.read(filepath, DataFrame, delim=',', skipto=2, header=[:MeV, :H_10])
    df.MeV = df.MeV * u"MeV"
    df.H_10 = df.H_10 * u"Sv*1.0e-12*cm^2"

    itp = interpolate((df.MeV,), df.H_10,
    Gridded(Linear()))

    return (MeV) -> itp(MeV), df
end

function create_interpolations(path)
    output_data = path 
    data_dict = load_data(output_data)
  
    data_interpolations = Dict()
    for (data_set_name, data_set) in zip(keys(data_dict), values(data_dict))
        Interpolations.deduplicate_knots!(data_set.Energy)
        interps = Dict()
        for (name, data) in zip(names(data_set), eachcol(data_set))
            interpolation = linear_interpolation(data_set.Energy, data)
            interps[name] = interpolation
        end
        data_interpolations[data_set_name] = interps
    end
    return data_interpolations
end
