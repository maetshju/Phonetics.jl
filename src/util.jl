using Distributions
using DataFrames
using Random

"""
    generateFormants(nTokens; [cats=[:iy, :aa, :uw], gender=[:w, :m]])

Generate synthetic formants from multivariate normal distributions based on observations from  Hillenbrand et al. (1995, Acoustic characteristics of American English vowels, DOI: 10.1121/1.411872). Currently supports generating vowels for /i/ as `:iy`, /ɑ/ as `:aa`, and /u/ as `:uw`, using values for men as `:m` and women as `:w`. One observation was dropped from the women /ɑ/ token because the F2 value could not be measured when Hillenbrand et al. collected the data. Values in the mean vectors and covariance matrices were rounded to two decimal places.

Args
======

* `nTokens` The number of tokens to generate for each category and gender pairing
* `cats` (keyword argument) A vector of vowel categories to generate tokens for
* `gender` (keyword argument) A vector of gender categories to generate tokens for
* `seed` A seed value for a `MersenneTwister` random number generator; allows for reproducible results; using the default value of `nothing` will use the system-generated random seed.
* `rng` An `AbstractRNG` object to use for random number generation; if the default value of `nothing` is used, a `MersenneTwister` object will be created
"""
function generateFormants(nTokens; cats=[:iy, :aa, :uw], gender=[:m, :w], seed=nothing, rng::T=nothing) where T <: Union{AbstractRNG, Nothing}

  if isnothing(seed) && isnothing(rng)
    rng = MersenneTwister()
  elseif isnothing(rng)
    rng = MersenneTwister(seed)
  end
  
  mappings = Dict()

  mappings[(:iy, :w)] = MultivariateNormal([437.25, 2761.31], [1650.06 1277.86; 1277.86 21738.56])
  mappings[(:aa, :w)] = MultivariateNormal([916.36, 1525.83], [8449.85 4354.50; 4354.50 15615.80])
  mappings[(:uw, :w)] = MultivariateNormal([459.67, 1105.52], [1496.06 -417.93; -417.93 42130.34])  

  mappings[(:iy, :m)] = MultivariateNormal([342.69, 2322.78], [796.99 493.36; 493.36 18580.77])
  mappings[(:aa, :m)] = MultivariateNormal([756.49, 1308.93], [3879.39 1751.56; 1751.56 12324.24])
  mappings[(:uw, :m)] = MultivariateNormal([379.67, 992.24], [1106.32 1482.52; 1482.52 12833.73])

  generated = []
  vowel = []
  gend = []

  for c in cats
    for g in gender
      
      if ! haskey(mappings, (c, g))
        error("Unsupported vowel and gender combination: ($c, $g)")
      end

      dist = mappings[(c, g)]
      data = rand(rng, dist, nTokens)
      push!(generated, data)
      vowel = [vowel; repeat([c], nTokens)]
      gend = [gend; repeat([g], nTokens)]
    end
  end

  gen = reduce(hcat, generated)
  return DataFrame(f1=gen[1,:], f2=gen[2,:], vowel=vowel, gender=gend)
end
