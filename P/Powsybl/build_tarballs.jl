using BinaryBuilder, Pkg

name = "Powsybl"
version = v"0.1"
sources = [
    GitSource("https://github.com/powsybl/powsybl.jl.git", "b1f9ec74fc703d85f5d34c8a5f7148a316852f1d"),
    GitSource("https://github.com/powsybl/pypowsybl.git", "4b2c40531890760872ee85c1b37dc600d6bbfeae")
]

julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]

script = raw"""
cd $WORKSPACE/srcdir

# Get binary for powsybl-java, generated with GraalVm
if [[ "${target}" == *-mingw* ]]; then
    wget https://github.com/powsybl/pypowsybl/releases/download/vBinariesDeployment/binaries-vBinariesDeployment-windows.zip -O powsybl-java.zip
fi
if [[ "${target}" == *-linux-* ]]; then
    wget https://github.com/powsybl/pypowsybl/releases/download/vBinariesDeployment/binaries-vBinariesDeployment-linux.zip -O powsybl-java.zip
fi
if [[ "${target}" == *-apple-* ]]; then
    wget https://github.com/powsybl/pypowsybl/releases/download/vBinariesDeployment/binaries-vBinariesDeployment-darwin.zip -O powsybl-java.zip
fi
unzip powsybl-java.zip -d $prefix

# Build powsybl-cpp API
cd pypowsybl/cpp && mkdir build && cd build
cmake ${WORKSPACE}/srcdir/pypowsybl/cpp -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DBUILD_PYPOWSYBL_JAVA=OFF -DBUILD_PYTHON_BINDINGS=OFF -DPYPOWSYBL_JAVA_LIBRARY_DIR=$prefix/lib -DPYPOWSYBL_JAVA_INCLUDE_DIR=$prefix/include -DCMAKE_INSTALL_PREFIX=$prefix
cmake --build . --target install --config Release

# Build julia wrapper
cd $WORKSPACE/srcdir/powsybl.jl && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ../cpp/powsybljl-cpp -DJulia_PREFIX=$prefix -DJlCxx_DIR=$prefix/lib/cmake/JlCxx -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_PREFIX_PATH=$prefix -DCMAKE_INSTALL_PREFIX=$prefix -DPOWSYBL_INSTALL_DIR=$prefix
cmake --build . --target install --config Release
install_license $WORKSPACE/srcdir/powsybl.jl/LICENSE.md
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

filter!(p -> arch(p) == "x86_64" && os(p) ∈ ("windows", "linux", "macos"), platforms)
platforms = expand_cxxstring_abis(platforms)

@show platforms

products = [
LibraryProduct(["math", "libmath"], :libmath)
LibraryProduct(["pypowsybl-java", "libpypowsybl-java"], :libpypowsybl_java)
LibraryProduct(["powsybl-cpp", "libpowsybl-cpp"], :libpowsybl_cpp)
LibraryProduct(["PowsyblJlWrap", "libPowsyblJlWrap"], :libPowsyblJlWrap)
]

dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("libjulia_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"12", julia_compat="1.6")
