module Homework7

using CSV
using DataFrames
using DelimitedFiles
using Interpolations
using Measurements
using OhMyREPL
using PhysicalConstants.CODATA2018
#  using Plots
using Unitful
using UnitfulUS
using Gtk4, Gtk4.GLib
using MutableNamedTuples
using CairoMakie

include("interpolation.jl")
include("data_loading.jl")
include("co_60_shielding.jl")
include("source_characterization.jl")

function julia_main()::Cint
    params = MutableNamedTuple(
        Co_60_act = 3000.0u"37GBq",
        r_surf = 3.0u"mm",
        r_steel = 2.0u"mm",
        r_air = 8.0u"sinch_us",
        r_lead = 10.5u"sinch_us",
        r_dist = 1.0u"m",
    )

    win = GtkWindow("Shielding analysis", 1200, 800)
    grid = GtkGrid()
    vbox = GtkBox(:v)
    hbox = GtkBox(:h)
    button = GtkButton("Run Analysis")
    button.action_name = "win.run_analysis"
    source_label = GtkLabel("")
    set_gtk_property!(hbox, :hexpand, true)

    param_fields = [
        (GtkLabel("Source activity (Ci)"), GtkEntry()),
        (GtkLabel("Source radius (mm)"), GtkEntry()),
        (GtkLabel("Steel thickness (mm)"), GtkEntry()),
        (GtkLabel("Air gap (in)"), GtkEntry()),
        (GtkLabel("Lead thickness (in)"), GtkEntry()),
        (GtkLabel("Evaluation Distance (m)"), GtkEntry()),
    ]

    param_fields[1][2].text = ustrip(params.Co_60_act / 37)
    param_fields[2][2].text = ustrip(params.r_surf)
    param_fields[3][2].text = ustrip(params.r_steel)
    param_fields[4][2].text = ustrip(params.r_air)
    param_fields[5][2].text = ustrip(params.r_lead)
    param_fields[6][2].text = ustrip(params.r_dist)

    for (idx, pair) in enumerate(param_fields)
        grid[1, idx] = pair[1]
        grid[2, idx] = pair[2]
    end

    config = CairoMakie.ScreenConfig(1.0, 1.0, :good, true, false, nothing)
    CairoMakie.activate!()
    canvas = GtkCanvas(400, 400, vexpand = true, hexpand = true)

    function run_analysis(a, par)::Nothing

        params.Co_60_act = parse(Float64, param_fields[1][2].text)u"37GBq"
        params.r_surf = parse(Float64, param_fields[2][2].text)u"mm"
        params.r_steel = parse(Float64, param_fields[3][2].text)u"mm"
        params.r_air = parse(Float64, param_fields[4][2].text)u"sinch_us"
        params.r_lead = parse(Float64, param_fields[5][2].text)u"sinch_us"
        params.r_dist = parse(Float64, param_fields[6][2].text)u"m"

        source_values = source_characteristics(params.Co_60_act, params.r_surf)
        data_interpolations = create_interpolations("./data")
        casing_results = source_casing(data_interpolations["Iron Beta Stopping"])
        shielding_results = lead_shielding(data_interpolations, params)

        source_string = "
        Source Properties:
            Mass:\t\t$(round(typeof(source_values.mass), source_values.mass, sigdigits=6))
            Volume:\t\t$(round(typeof(source_values.volume), source_values.volume, sigdigits=6))
            Radius:\t\t$(round(typeof(source_values.radius), source_values.radius, sigdigits=6))
            Height:\t\t$(round(typeof(source_values.height), source_values.height, sigdigits=6))

        Casing β Shielding Properties with thickness $(params.r_steel):
            Energy 1:\t$(round(typeof(casing_results.Energies[1]), casing_results.Energies[1], sigdigits=6))
            Distance 1:\t$(round(typeof(casing_results.Distances[1]), casing_results.Distances[1], sigdigits=6))
            Energy 2:\t$(round(typeof(casing_results.Energies[2]), casing_results.Energies[2], sigdigits=6))
            Distance 2:\t$(round(typeof(casing_results.Distances[2]), casing_results.Distances[2], sigdigits=6))

        Exposure Calculations of $(params.Co_60_act) Co-60 at $(params.r_dist):
            Intensity of $(round(typeof(shielding_results.Energies[1]), shielding_results.Energies[1], sigdigits=6)):
            \t\t\t\t$(round(typeof(shielding_results.Intensities[1]), shielding_results.Intensities[1], sigdigits=6))
            Intensity of $(round(typeof(shielding_results.Energies[2]), shielding_results.Energies[2], sigdigits=6)):
            \t\t\t\t$(round(typeof(shielding_results.Intensities[2]), shielding_results.Intensities[2], sigdigits=6))
            Exposure:\t$(round(typeof(shielding_results.exposure), shielding_results.exposure, sigdigits=6))
        "
        set_gtk_property!(source_label, :label, source_string)

        @guarded draw(canvas) do widget
            f = Figure()
            ax = Axis(
                f[1, 1],
                yscale = log10,
                xlabel = "Distance (mm)",
                ylabel = "Flux (Bq/cm²)",
            )
            e1_graph = lines!(
                ax,
                ustrip.(shielding_results.plotting[1]),
                ustrip.(uconvert.(u"Bq/cm^2", shielding_results.plotting[2][1])),
            )
            e2_graph = lines!(
                ax,
                ustrip.(shielding_results.plotting[1]),
                ustrip.(uconvert.(u"Bq/cm^2", shielding_results.plotting[2][2])),
            )
            surf_line = vlines!(
                                ustrip.(params.r_surf),
                               linestyle=:dash
                              ) 
            steel_line = vlines!(
                                ustrip.(uconvert(u"mm", params.r_surf + params.r_steel)),
                               linestyle=:dash
                              ) 
            air_line = vlines!(
                                ustrip.(uconvert(u"mm", params.r_surf + params.r_air + params.r_steel)),
                               linestyle=:dash
                              ) 
            lead_line = vlines!(
                                ustrip.(uconvert(u"mm", params.r_surf + params.r_air + params.r_steel + params.r_lead)),
                               linestyle=:dash
                              ) 
            exp_line = vlines!(
                                ustrip.(uconvert(u"mm", params.r_dist)),
                               linestyle=:dash
                              ) 
            Legend(
                f[1, 2],
                [e1_graph, e2_graph, surf_line, steel_line, air_line, lead_line, exp_line],
                [
                    "$(round(typeof(shielding_results.Energies[1]), shielding_results.Energies[1], sigdigits=6)) γ",
                    "$(round(typeof(shielding_results.Energies[2]), shielding_results.Energies[2], sigdigits=6)) γ",
                    "Source surface ($(params.r_surf))",
                    "Steel surface ($(uconvert(u"mm", params.r_surf + params.r_steel)))",
                    "Lead shield starts ($(uconvert(u"mm", params.r_surf + params.r_steel + params.r_air)))",
                    "Lead sheild ends ($(uconvert(u"mm", params.r_surf + params.r_steel + params.r_air + params.r_lead)))",
                    "Exposure distance ($(uconvert(u"mm",params.r_dist)))",
                ],
            )
            CairoMakie.autolimits!(ax)
            screen = CairoMakie.Screen(f.scene, config, Gtk4.cairo_surface(canvas))
            CairoMakie.resize!(f.scene, Gtk4.width(widget), Gtk4.height(widget))
            CairoMakie.cairo_draw(screen, f.scene)
        end

        nothing
    end

    action_group = GSimpleActionGroup()
    add_action(GActionMap(action_group), "run_analysis", run_analysis)
    push!(win, Gtk4.GLib.GActionGroup(action_group), "win")

    push!(vbox, grid)
    push!(vbox, button)
    push!(vbox, source_label)
    push!(hbox, vbox)
    push!(hbox, canvas)
    push!(win, hbox)
    return 0
end

end
