# Acoustic distance

Recent work has used [dynamic time warping](https://en.wikipedia.org/wiki/Dynamic_time_warping) on sequences of [Mel frequency cepstral coefficient (MFCC)](https://en.wikipedia.org/wiki/Mel-frequency_cepstrum) vectors to compute a form of acoustic distance (Mielke, 2012; Kelley, 2018; Kelley & Tucker, 2018; Bartetlds et al., 2020). There are a number of convenience functions provided in this package. For the most part, they wrap the [DynamicAxisWarping.jl](https://github.com/baggepinnen/DynamicAxisWarping.jl) and [MFCC.jl](https://github.com/JuliaDSP/MFCC.jl) packages. See also the [Phonological CorpusTools page on acoustic similarity](https://corpustools.readthedocs.io/en/latest/acoustic_similarity.html).

## Computing acoustic distance

Let's start by creating some sample sounds to work with. You could also load in your own sounds from file as well using the `Sound` constructor that takes a filename.

```@example
using Phonetics # hide
using Random
rng = MersenneTwister(9)
x = rand(rng, 1000)
y = rand(rng, 3000)
acdist(x, y)
```

The output value is the result of performing dynamic time warping on the `x` and `y`. If `x` and `y` are `Sound` objects (in this example, they are not), they will first be converted to MFCC vectors with the `sound2mfcc` function. This value has been found to situate phonological similarity in terms of acoustics (Mielke, 2012), reflect aspects of the activation/competition process during spoken word recognition (Kelley, 2018; Kelley & Tucker, 2018), and judgments of nativelike pronunciation (Bartelds et al., 2020).

As an implementation note, the distance metric used to compare the MFCC vectors is the squared Euclidean distance between two vectors.

## Acoustic distinctiveness

Kelley (2018) and Kelley & Tucker (2018) introduced the concept of acoustic distinctiveness. It is how far away a word is, on average, from all the other words in a language. The `distinctiveness` function performs this calculation.

```@example
using Phonetics # hide
using Random
rng = MersenneTwister(9)
x = rand(rng, 1000)
y = rand(rng, 3000)
z = rand(rng, 10000)
a = [Sound(x, 8000), Sound(y, 8000), Sound(z, 8000)]
distinctiveness(a[1], a[2:3])
```

The number is effectively an index of how acoustically unique a word is in a language.

## Sequence averaging

Kelley & Tucker (2018) also used the dynamic barycenter averaging (Petitjean et al., 2011) technique to create "average" acoustic representations of English words, in an attempt to better model the kind of acoustic representation a listener may be accessing when hearing a word (given that a listener has heard most words more than just once). The interface for calculating the average sequence is with the `avgseq` function.

```@example
using Phonetics # hide
using Random
rng = MersenneTwister(9)
x = rand(rng, 1000)
y = rand(rng, 3000)
z = rand(rng, 10000)
a = [Sound(x, 8000), Sound(y, 8000), Sound(z, 8000)]
avgseq(a)
```

## References

Bartelds, M., Richter, C., Liberman, M., & Wieling, M. (2020). A new acoustic-based pronunciation distance measure. *Frontiers in Artificial Intelligence, 3*, 39.

Mielke, J. (2012). *A phonetically based metric of sound similarity. Lingua, 122*(2), 145-163.

Kelley, M. C. (2018). How acoustic distinctiveness affects spoken word recognition: A pilot study. Presented at the 11th International Conference on the Mental Lexicon (Edmonton, AB). [https://doi.org/10.7939/R39G5GV9Q](https://doi.org/10.7939/R39G5GV9Q)

Kelley, M. C., & Tucker, B. V. (2018). Using acoustic distance to quantify lexical competition. University of Alberta ERA (Education and Research Archive). [https://doi.org/10.7939/r3-wbhs-kr84](https://doi.org/10.7939/r3-wbhs-kr84)

Petitjean, F., Ketterlin, A., & Gançarski, P. (2011). A global averaging method for dynamic time warping, with applications to clustering. *Pattern Recognition, 44*(3), 678–693.
