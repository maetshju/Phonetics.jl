module Phonetics

include("sound.jl")
export Sound

# Depending on SSL versions, loading `VowelDensity.jl` before
# `acdist.jl` can cause the build to crash. It seems like an
# interaction between QHull in `VowelDensity.jl` and something in
# MFCC (probably related to HDF5, which depends on OpenSSL_jll,
# with some degrees of separation)
include("acdist.jl")
export acdist, avgseq, distinctiveness, sound2mfcc

include("VowelDensity.jl")
export Formants, VowelSpace, area, vdi, vowelspaceplot

include("normalize.jl")
export neareyE, neareyI, lobanov, formantWiseLogMean, nearey1, logmeanI, formantBlindLogMean, nearey2, logmeanE

include("vowelplot.jl")
export vowelplot, ellipsePts, vowelhull, hullarea

include("util.jl")
export generateFormants

include("phon_spectrogram.jl")
export phonspec

include("upt.jl")
include("vptree.jl")
include("pnd.jl")
include("phnprb.jl")

export
    pnd,
    lev,
    upt,
    phnprb,
    radiusSearch,
    nneighbors,
    TextVPTree

end # module
