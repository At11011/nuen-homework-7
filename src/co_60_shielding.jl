# Lead shielding
function lead_shielding(data_interpolations, params) 
    lead_data = data_interpolations["Lead Gamma Attenuation"]
    tissue_data = data_interpolations["Tissue Gamma Attenuation"]
    iron_data = data_interpolations["Iron Gamma Attenuation"]
    air_data = data_interpolations["Air Gamma Attenuation"]
    
    E = [
    1.1732u"MeV",
    1.33225u"MeV"
    ]# Gamma energies
    r_surf = params.r_surf # Radius of bare source
    r_steel = params.r_steel # Thickness of steel source casing
    r_air = params.r_air # Airgap between source and walls of chamber 
    r_lead = params.r_lead # Thickness of lead chamber wall
    Co_60_act = params.Co_60_act
    ρₚ = 1.127u"g/cm^3" # Density of tissue-plastic
    ρₗ = 11.348u"g/cm^3" # Density of lead at 20 °C
    ρᵢ = 7.874u"g/cm^3" # Density of iron at 20 °C
    tissue_en = tissue_data["En"][E] * ρₚ
    r = params.r_dist
 
    function intensity(r)
        if r < r_surf
            error("Radius is inside of source")
        end  
        I = Co_60_act / (4π*r^2) # Geometric attenuation
        # Attenuation by steel casing
        ρ = ρᵢ
        μ = iron_data["Mass"][E] * ρ
        r_attn = r_surf
        if r < r_attn + r_steel
            I = @. I * exp(-(r - r_attn) * μ) # attenuation of γ
            return I
        else
            I = @. I * exp(-r_steel * μ) # attenuation of γ
        end
        # Air attenuation
        P = 1u"atm"
        R = BoltzmannConstant * AvogadroConstant
        T = 293.15u"K"
        Mₐ = 28.96u"g/mol"
        ρ = P * Mₐ / (R*T) # Density of air at 20 °C
        μ = air_data["Mass"][E] * ρ
        r_attn += r_steel
        if r < r_attn + r_air
            I = @. I * exp(-(r - r_steel) * μ)
            #  println("Iₐ: $I")
            return I
        else
            I = @. I * exp(-r_air * μ)
        end
        # Lead attenuation
        ρ = ρₗ
        μ = lead_data["Mass"][E] * ρ
        r_attn += r_air
        if r < r_attn + r_lead
            I = @. I * exp(-(r - r_attn) * μ) # attenuation of first γ
            return I
        else
            I = @. I * exp(-r_lead * μ) # attenuation of first γ
        end
        # Air attenuation
        P = 1u"atm"
        R = BoltzmannConstant * AvogadroConstant
        T = 293.15u"K"
        Mₐ = 28.96u"g/mol"
        ρ = P * Mₐ / (R*T) # Density of air at 20 °C
        μ = air_data["Mass"][E] * ρ
        r_attn += r_lead
        I = @. I * exp(-(r - r_attn) * μ) # attenuation of first γ
        return I
    end
    I = intensity(r)

    B, _ = create_buildup_interpolation_function("./data/lead_buildup.txt")
    R, _ = create_reponse_interpolation_function("./data/response_function.txt")
    IₜBR = sum(@. I * B(E, lead_data["Mass"][E] * r_lead * ρₗ) * R(E)) 
    exposure = uconvert(u"mSv/yr",  IₜBR) * (5/7) * (8/24)
    
    #  println("Attenuation for point source of activity $Co_60_act at $r.")
    #  println("\tAttenuated intensity of $(E[1]) γ at $r: $(uconvert(u"Bq/cm^2", I[1]))")
    #  println("\tAttenuated intensity of $(E[2]) γ at $r: $(uconvert(u"Bq/cm^2", I[2]))")
    #  print("\tExposure by γ at $r: ")
    #  printstyled("$(round(typeof(exposure), exposure, sigdigits=8))"; color = :red)
    #  println()
    
    r_lim = uconvert(u"mm", r)
    r_range = logrange(3, ustrip(r_lim), length = 1000) * unit(r_lim)
    i_range = intensity.(r_range)
    i_range₁ = [i_val[1] for i_val in i_range]
    i_range₂ = [i_val[2] for i_val in i_range]

    #  p1 = plot(
    #      r_range,
    #      uconvert.(u"Bq/cm^2", i_range₁),
    #      yaxis = :log,
    #      xlabel="Radial distance from source",
    #      ylabel="Radiation intensity",
    #      label="Attenuation of $(E[1]) γ",
    #      title="Attenuation versus radial distance\nfrom Co-60 source with shileding"
    #  )
    #  plot!(
    #      p1,
    #      r_range,
    #      uconvert.(u"Bq/cm^2", i_range₂),
    #      label = "Attenuation of $(E[2]) γ"
    #  )
    #  r_attn = r_surf
    #  r_attn += r_steel
    #  vline!(p1,[r_attn],label="Steel ($r_steel thick)",style=:dash)
    #  r_attn += r_air
    #  vline!(p1,[r_attn],label="Blood chamber ($r_air gap)",style=:dash)
    #  r_attn += r_lead
    #  vline!(p1,[r_attn],label="Lead shielding ($r_lead thick)",style=:dash)
    #  savefig("./output/attenuation_graph.png")
    return (Energies = E, Intensities = I, exposure = exposure, plotting = (r_range,[i_range₁, i_range₂]))
end
