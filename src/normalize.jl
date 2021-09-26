using Statistics
using DataFrames
using StatsBase

"""
    lobanov(f1, f2, vowel, speaker)

Performs the Lobanov normalization routine, which calculates the z-score of each speaker's F1 and F2. See Lobanov (1971, Classification of Russian vowels spoken by different speakers. J. Acoust. Soc. Am. 49(2B), 606–608) for more details.

Args
=====

* `f1`  F1 values
* `f2` F2 values
* `vowel` Vowel categories; not used in calculation, but passed in to keep them linked with their appropriate formant and speaker information
* `speaker` An `Array` of speaker IDs; can be integers, symbols, string, and any other data type supported by the `groupby` function in the `DataFrames` package
"""
function lobanov(f1, f2, vowel, speaker)
  d  = DataFrame(f1=f1, f2=f2, vowel=vowel, speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  d = combine(groups, :f1 => zscore => :f1, :f2 => zscore => :f2, :vowel => :vowel, :rowN => :rowN)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :vowel, :speaker]]
  return d
end

"""
    neareyI(f1, f2, vowel, speaker)

Performs the Nearey formant intrinsice normalization routine, which logs the formants and subtracts the mean log F1 value from the log F1 values and the mean log F2 value from the F2 values. See Nearey (1978, phonetic feature system for vowels, Indiania University Linguistics Club) for more details.

Args
=====

* `f1`  F1 values
* `f2` F2 values
* `vowel` Vowel categories; not used in calculation, but passed in to keep them linked with their appropriate formant and speaker information
* `speaker` An `Array` of speaker IDs; can be integers, symbols, string, and any other data type supported by the `groupby` function in the `DataFrames` package
"""
function neareyI(f1, f2, vowel, speaker)
  d  = DataFrame(f1=log.(f1), f2=log.(f2), vowel=vowel, speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  lgmnI(x) = x .- mean(x)

  # apply the formant INTRINSIC normalization by group and recombine
  d = combine(groups, [:f1, :f2, :vowel, :rowN] => ((x, y, v, r) -> (f1=lgmnI(x), f2=lgmnI(y), vowel=v, rowN=r)) => AsTable)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :vowel, :speaker]]
  return d
end

# aliases for neareyI that have appeared in the literature
formantWiseLogMean = nearey1 = logmeanI = neareyI


"""
    neareyI(f1, f2, vowel, speaker)

Performs the Nearey formant extrinsic normalization routine, which logs the formants and subtracts the mean of all log formant values from each log formant value. See Nearey (1978, phonetic feature system for vowels, Indiania University Linguistics Club) for more details.

Args
=====

* `f1`  F1 values
* `f2` F2 values
* `vowel` Vowel categories; not used in calculation, but passed in to keep them linked with their appropriate formant and speaker information
* `speaker` An `Array` of speaker IDs; can be integers, symbols, string, and any other data type supported by the `groupby` function in the `DataFrames` package
"""
function neareyE(f1, f2, vowel, speaker)
  d  = DataFrame(f1=log.(f1), f2=log.(f2), vowel=vowel, speaker=speaker)
  d.rowN = collect(1:size(d, 1))
  groups = groupby(d, :speaker)
  lgmnE(x, y) = x .- mean([x; y])

  # apply the formant EXTRINSIC normalization by group and recombine
  d = combine(groups, [:f1, :f2, :vowel, :rowN] => ((x, y, v, r) -> (f1=lgmnE(x, y), f2=lgmnE(y, x), vowel=v, rowN=r)) => AsTable)
  sort!(d, :rowN)
  d = d[:, [:f1, :f2, :vowel, :speaker]]
  return d
end

# aliases for neareyE that have appeared in the literature, except for
# formant-blind log-mean (formant-blind-log-mean), which does not seem to
# have appeared and is named here as an analogue to
# formantwiselogmean (formant-wise-log-mean)
formantBlindLogMean = nearey2 = logmeanE = neareyE