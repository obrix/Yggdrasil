# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1200.000"
gap_lib_version = v"400.1200.000"
name = "orb"
upstream_version = v"4.8.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.gz",
                  "1c88a8ee980cdfd135c83eac9ebf8f35a2961eee3fb7e97d229e595831a0a6db"),
]

# Bash recipe for building across all platforms
script = raw"""
cd orb*
./configure ${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/orb.so", :orb),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
