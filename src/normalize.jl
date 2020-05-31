using Statistics
using DataFrames
using StatsBase

"""
    lobanov(f1, f2, vowel, speaker)

Performs the Lobanov normalization routine, which calculates the z-score of each speaker's F1 and F2.

See Lobanov (1971, Classification of Russian vowels spoken by different speakers. J. Acoust. Soc. Am. 49(2B), 606–608) for more details. **Note** that this function will **not** preserve the order of the rows if the speaker IDs are not all in sequential order.

Args
=====

* `f1` An `Array` of F1 values
* `f2` An `Array` of F2 values
* `speaker` An `Array` of speaker IDs; can be integers, symbols, string, and any other data type supported by the `groupby` function in the `DataFrames` package

Returns
========

A `DataFrame` object the columns `f1`, `f2`, `speaker`. The final row order is guaranteed to preserve the row order of the data passed in.
"""
function lobanov(f1, f2, speaker)
  d  = DataFrame(f1=f1, f2=f2, speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  d = combine(groups, :f1 => zscore => :f1, :f2 => zscore => :f2, :rowN => :rowN)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :speaker]]
  return d
end

function neareyI(f1, f2, speaker)
  d  = DataFrame(f1=log.(f1), f2=log.(f2), speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  lgmnI(x) = x .- mean(x)

  # apply the formant INTRINSIC normalization by group and recombine
  d = combine([:f1, :f2, :rowN] => (x, y, r) -> (f1=lgmnI(x), f2=lgmnI(y), rowN=r), groups)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :speaker]]
  return d
end

# aliases for neareyI that have appeared in the literature
formantWiseLogMean = nearey1 = logmeanI = neareyI

function neareyE(f1, f2, speaker)
  d  = DataFrame(f1=log.(f1), f2=log.(f2), speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  lgmnE(x, y) = x .- mean([x; y])

  # apply the formant EXTRINSIC normalization by group and recombine
  d = combine([:f1, :f2, :rowN] => (x, y, r) -> (f1=lgmnE(x, y), f2=lgmnE(y, x), rowN=r), groups)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :speaker]]
  return d
end

# aliases for neareyE that have appeared in the literature, except for
# formant-blind log-mean (formant-blind-log-mean), which does not seem to
# have appeared and is named here as an analogue to
# formantwiselogmean (formant-wise-log-mean)
formantBlindLogMean = nearey2 = logmeanE = neareyE