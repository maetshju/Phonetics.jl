module Phonetics

include("VowelDensity.jl")
export Formants, VowelSpace, plot, plot!, area, vdi

include("normalize.jl")
export neareyE, neareyI, lobanov, formantWiseLogMean, nearey1, logmeanI, formantBlindLogMean, nearey2, logmeanE

include("vowelplot.jl")
export vowelPlot, ellipsePts

end # module
