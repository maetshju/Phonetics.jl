using DynamicAxisWarping
using MFCC
using Distances
using DataFrames
using Statistics

"""
    acdist(s1, s2; [method=:dtw, dist=SqEuclidean(), radius=10])

Calculate the acoustic distance between `s1` and `s2` with `method` version of dynamic time warping and `dist` as the interior distance function. Using `method=:dtw` uses vanilla dynamic time warping, while `method=:fastdtw` uses the fast dtw approximation. Note that this is not a true mathematical distance metric because dynamic time warping does not necessarily satisfy the triangle inequality, nor does it guarantee the identity of indiscernibles.

Args
=====

* `s1` Features-by-time array of first sound to compare
* `s2` Features-by-time array of second sound to compare
* `method` (keyword) Which method of dynamic time warping to use
* `dist` (keyword) Any distance function implementing the `SemiMetric` interface from the `Distances` package
* `dtwradius` (keyword) maximum warping radius for vanilla dynamic timew warping; if no value passed, no warping constraint is used argument unused when method=:fastdtw
* `fastradius` (keyword) The radius to use for the fast dtw method; argument unused when method=:dtw
"""
function acdist(s1, s2; method=:dtw, dist=SqEuclidean(), dtwradius=nothing, fastradius=10)
  
  if method == :dtw
    if isnothing(dtwradius) dtwradius = max(size(s1, 2), size(s2, 2)) end
    imin, imax = radiuslimits(dtwradius, size(s1, 2), size(s2, 2))
    if last(imax) < size(s2, 2) imax[end] = size(s2, 2)
    return dtw(s1, s2, dist, imin, imax)[1]
  elseif method == :fastdtw
    return fastdtw(s1, s2, dist, fastradius)[1]
  else
    error("Unsupported method argument.")
  end
end

"""
    acdist(s1::Sound, s2::Sound, rep=:mfcc; [method=:dtw, dist=SqEuclidean(), radius=10])

Convert `s1` and `s2` to a frequency representation specified by `rep`, then calculate acoustic distance between `s1` and `s2`. Currently only `:mfcc` is supported for `rep`, using defaults from the `MFCC` package except that the first coefficient for each frame is removed and replaced with the sum of the log energy of the filterbank in that frame, as is standard in ASR.
"""
function acdist(s1::Sound, s2::Sound, rep=:mfcc; method=:dtw, dist=SqEuclidean(), dtwradius=nothing, fastradius=10)

  if rep == :mfcc
    r1 = sound2mfcc(s1)
    r2 = sound2mfcc(s2)
  else
    error("Unsupported rep argument. Plesae consult documentation with ?acdist")
  end

  return acdist(r1, r2, method=method, dist=dist, dtwradius=dtwradius, fastradius=fastradius)
end

"""
    avgseq(S; [method=:dtw, dist=SqEuclidean(), radius=10, center=:medoid, dtwradius=nothing, progress=false])

Return a sequence representing the average of the sequences in `S` using the dba method for sequence averaging. Supports `method=:dtw` for vanilla dtw and `method=:fastdtw` for fast dtw approximation when performing the sequence comparisons. With `center=:medoid`, finds the medoid as the sequence to use as the initial center, and with `center=:rand` selects a random element in `S` as the initial center.

Args
======

* `S` An array of sequences to average
* `method` (keyword) The method of dynamic time warping to use
* `dist` (keyword) Any distance function implementing the `SemiMetric` interface from the `Distances` package
* `radius` (keyword) The radius to use for the fast dtw method; argument unused when method=:dtw
* `center` (keyword) The method used to select the initial center of the sequences in `S`
* `dtwradius` (keyword) How far a time step can be mapped when comparing sequences; passed directly to `DTW` function from `DynamicAxisWarping`; if set to `nothing`, the length of the longest sequence will be used, effectively removing the radius restriction
* `progress` Whether to show the progress coming from `dba`
"""
function avgseq(S; method=:dtw, dist=SqEuclidean(), fastradius=10, center=:medoid, dtwradius=nothing, progress=false)

  if isnothing(dtwradius)
    dtwradius = maximum(size(s, 2) for s in S)
  end

  if method == :dtw
    d = DTW(dtwradius, dist)
  elseif method == :fastdtw
    d = FastDTW(radius, dist)
  else
    error("Unsupported method argument.")
  end

  if center == :medoid
    D = zeros(length(S), length(S))
    for idx in CartesianIndices(D)
      D[idx] = acdist(S[idx[1]], S[idx[2]], method=method, dist=dist, dtwradius=dtwradius, fastradius=fastradius)[1]
    end
    sums = vec(sum(D, dims=1))
    init = S[argmin(sums)]
  elseif center == :rand
    init = rand(S)
  end

  return dba(S, d, init_center=init, show_progress=progress)[1]
end

"""
    avgseq(S::Array{Sound}, rep=:mfcc; [method=:dtw, dist=SqEuclidean(), radius=10, center=:medoid, dtwradius=nothing, progress=false])

Convert the `Sound` objects in `S` to a representation designated by `rep`, then find the average sequence of them. Currently only `:mfcc` is supported for `rep`, using defaults from the `MFCC` package except that the first coefficient for each frame is removed and replaced with the sum of the log energy of the filterbank in that frame, as is standard in ASR.
"""
function avgseq(S::Array{Sound}, rep=:mfcc; method=:dtw, dist=SqEuclidean(), fastradius=10, center=:medoid, dtwradius=nothing, progress=false)
  if rep == :mfcc
    S = sound2mfcc.(S)
  else
    error("Unsupported rep argument. Please consult documentation with ?acdist")
  end

  return avgseq(S, method=method, dist=dist, fastradius=fastradius, center=center, dtwradius=dtwradius, progress=false)
end

"""
    distinctiveness(s, corpus; [method=:dtw, dist=SqEuclidean(), radius=10, reduction=mean])

Calculates the acoustic distinctiveness of `s` given the corpus `corpus`. The `method`, `dist`, and `radius` arguments are passed into `acdist`. The `reduction` argument can be any function that reduces an iterable to one number, such as `mean`, `sum`, or `median`. 

For more information, see Kelley (2018, September, How acoustic distinctiveness affects spoken word recognition: A pilot study, DOI: 10.7939/R39G5GV9Q) and Kelley & Tucker (2018, Using acoustic distance to quantify lexical competition, DOI: 10.7939/r3-wbhs-kr84).
  """
function distinctiveness(s, corpus; method=:dtw, dist=SqEuclidean(), dtwradius=nothing, fastradius=10, reduction=mean)
  return reduction(map(x -> acdist(s, x, method=method, dist=dist, dtwradius=nothing, fastradius=fastradius), corpus))
end

"""
    distinctiveness(s::Sound, corpus::Array{Sound}, rep=:mfcc; [method=:dtw, dist=SqEuclidean(), radius=10, reduction=mean])

Converts `s` and `corpus` to a representation specified by `rep`, then calculates the acoustic distinctiveness of `s` given `corpus`. Currently only `:mfcc` is supported for `rep`, using defaults from the `MFCC` package except that the first coefficient for each frame is removed and replaced with the sum of the log energy of the filterbank in that frame, as is standard in ASR.
"""
function distinctiveness(s::Sound, corpus::Array{Sound}, rep=:mfcc; method=:dtw, dist=SqEuclidean(), dtwradius=nothing, fastradius=10, reduction=mean)

  if rep == :mfcc
    s = sound2mfcc(s)
    corpus = sound2mfcc.(corpus)
  else
    error("Unsupported rep argument")
  end

  return distinctiveness(s, corpus, method=method, dist=dist, dtwradius=nothing, fastradius=fastradius, reduction=reduction)
end

function sound2mfcc(s::Sound; useFrameEngery=true, kw...)
  m, e, _ = mfcc(s.samples, s.sr; kw...)
  if useFrameEngery
    e = log.(sum(e, dims=2))
    m[:,1] = e
  end
  return Array(m')
end