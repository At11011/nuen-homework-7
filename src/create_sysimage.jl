using PackageCompiler
create_sysimage(
    ["Homework7"],
    sysimage_path = "./lib/sys_image.so",
    precompile_execution_file = "./src/precompile_script.jl",
)
