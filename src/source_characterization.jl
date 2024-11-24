# Source characteristics
function source_characteristics(act, radius)
    T_12 = 5.2714u"yr" # Half life of Cobalt 60
    λ = uconvert(u"s^-1", log(2)/T_12) # Decay constant of Cobalt 60
    M = 59.9338222u"g/mol" # Molar mass of cobalt-60
    ρ  = 8.834u"g/cm^3" # Density of cobalt
    m = uconvert(u"g", act * M / (λ * AvogadroConstant)) # Mass of the source
    r = radius # Radius of the source
    V = uconvert(u"mm^3", m / ρ) # Volume of the source
    h = uconvert(u"mm", V / (π * r^2))

    #  output_string = ""
    #  output_string *= "For a cylindrical $act Cobalt-60 source:\n"
    #  output_string *= "Half life: $T_12\n"
    #  output_string *= "Decay Constant: $λ\n"
    #  output_string *= "Mass: $m\n"
    #  output_string *= "Volume: $V, radius: $r, height: $h\n"
    return (mass = m, volume = V, radius = r, height = h)
end

# Source casing
function source_casing(iron_data)
    E₁, E₂ = 0.31u"MeV", 1.48u"MeV" # Beta energies
    ρ = 6.98u"g/cm^3" # Density of iron at 20 °C
    distance₁, distance₂ = uconvert.(u"mm", iron_data["CSDA"][[E₁, E₂]]./ρ) # Distance of source
    output_string = ""
    output_string *= "Casing beta shielding:\n"
    output_string *= "Distance of $E₁: $distance₁\nDistance of $E₂: $distance₂\n"
    return (Energies = [E₁, E₂], Distances = [distance₁, distance₂])
end
