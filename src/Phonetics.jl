module Phonetics

include("sound.jl")
export Sound

include("VowelDensity.jl")
export Formants, VowelSpace, area, vdi, vowelspaceplot

include("normalize.jl")
export neareyE, neareyI, lobanov, formantWiseLogMean, nearey1, logmeanI, formantBlindLogMean, nearey2, logmeanE

include("vowelplot.jl")
export vowelplot, ellipsePts

include("acdist.jl")
export acdist, avgseq, distinctiveness, sound2mfcc

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
