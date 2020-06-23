# Lexical characteristics

There are some functions to calculate common lexical characteristics of words. These characteristics are a reflection of how a word relates to all the other words in a language, that is, how they relate to all other words in the lexicon.

## Phonological neighborhood density

Phonological neighborhood density, as described by Luce & Pisoni (1998), as a concept is a set of words that sound similar to each other. Vitevitch & Luce (2016) explain that it's common to operationalize this concept as the number of words that have a Levenshtein distance (minimal number of segment additions, subtractions, or substitutions to transform one word or string into another) of exactly 1 from the word in question.

The `pnd` function allows a user to calculate this value for a list of words based on a given corpus. The following example shows how to use the `pnd` function. Note that the entries in the sample corpus are given using the Arpabet transcription scheme.

```@example
using Phonetics
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
pnd(sample_corpus, [["K", "AE1", "T"]])
```

As we can see, [K AA1 T] *cat* has 2 phonological neighbors in the given corpus, so it has a phonological neighborhood density of 2. The data is returned in a `DataFrame` so that processing that uses tabular data can be performed.

A more likely scenario is calculating the phonological neighborhood density for each item in the CMU Pronouncing dictionary. For the purposes of this example, I'll assume you have already downloaded the [CMU Pronouncing Dictionary](http://www.speech.cs.cmu.edu/cgi-bin/cmudict). There is a bit of extra information at the top of the document that needs to be deleted, so make sure the first line in the document is the entry for "!EXCLAMATION-POINT".

Now, the first thing we need to do is read the file into Julia and process it into a usable state. Because we're interested in the phonological transcriptions here, we'll strip away the orthographic representation.

```julia
using Phonetics
corpus = Vector()
open("cmudict-0.7b") do f
  lines = readlines(f)
  for line in lines
    phonological_transcription = split(split(line, "  ")[2])
    push!(corpus, phonological_transcription)
  end
end
```

Notice that we called `split` twice. The **first** time was to split the orthographic representation from the phonological one, and they're separated by two spaces. We wanted the phonological transcription, so we took the second element from the `Array` that results from that call to `split`. The **second** call to `split` was to split the phonological representation into another `Array`. This is necessary because the CMU Pronouncing Dictionary uses a modified version of the Aprabet transcription scheme and doesn't always use only 1 character to represent a particular phoneme. So we can't just process each individual item in a string as we might be able to do for a 1 character to 1 phoneme mapping like the International Phonetic Alphabet. Representing each phoneme as one element in an `Array` allows us to process the data correctly.

Now that we have the corpus set up, all we need to do is call the `pnd` function.

```julia
neighborhood_density = pnd(corpus, corpus)
```

The output from `pnd` is a `DataFrame` where the queries are in the first column and the associated neighborhood densities are in the second column. This `DataFrame` can then be used in subsequent statistical analyses or saved to a file for use in other programming language or software like R.

### Implementation note

The intuitive way of coding phonological neighborhood density involves comparing every item in the corpus against every other item in the corpus and counting how many neighbors each item has. However, this is computationally inefficient, as there are approximately ``n^2`` comparisons that must be performed. In this package, this process is sped up by using a spatial data structure called a [vantage-point tree](https://en.wikipedia.org/wiki/Vantage-point_tree). This data structure is a binarily branching tree where all the items on the left of a node are less than a particular distance away from the item in the node, and all those on the right are greater than or equal to that particular distance.

Because of the way that the data is organized in a vantage-point tree, fewer comparisons need to be made. While descending the tree, it can be determined whether any of the points in a branch from a particular node should be searched or not, limiting the number of branches that need to be traversed. In practical terms, this means that the Levenshtein distance is calculated fewer times for each item, and the phonological neighborhood density should be calculated faster for a data set than from using the traditional approach that compares each item to all the other ones in the corpus. At the time of writing this document, I am not aware of any phonological neighborhood density calculator/script that offers this kind of speedup.

## Phonotactic probability

The phonotactic probability is likelihood of observing a sequence in a given language. It's typically calculated as either the co-occurrence probability of a series of phones or diphones, or the cumulative transitional probability of moving from one portion of the sequence to the next.

This package currently provides the co-occurrence method of calculating the phonotactic probability, and this can be done taking the position of a phone or diphone into account, or just looking at the co-occurrence probability. By means of example:

```@example
using Phonetics # hide
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
freq = [1,1,1,1,1,1]
p = prod([4,4,4] / 20)
phnprb(sample_corpus, freq, [["K", "AE1", "T"]])
```

In this example, each phone has 4 observations in the corpus, and the likelihood of observing each of those phones is 4/20. Because there are 3, the phonotactic probability of this sequence is ``{\frac{4}{20}}^3``, which is 0.008. Floating point errors sometimes occur in the arithmetic in programming,
but this is unavoidable.

```@example
using Phonetics # hide
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
freq = [1,1,1,1,1,1]
p = prod([3,2,3,2]/26)
phnprb(sample_corpus, freq, [["K", "AE1", "T"]]; nchar=2)
```

In this example here, the input is padded so that the beginning and ending of the word are taken into account when calculating the phonotactic probability. There are 3 counts of [. K] \(where [.] is the word boundary symbol\), 2 counts of [K AE1], 3 counts of [AE1 T], and 2 counts of [T .]. There are 26 total diphones observed in the corpus, so the phonotactic probability is calculated as

```math
\frac{3}{26} \times \frac{2}{26} \times \frac{3}{26} \times \frac{2}{26} \,.
```

## Uniqueness point

The uniqueness point of a word is defined as the segment in a sequence after which that sequence can be uniquely identified. In cohort models of speech perception, it is after this point that a listener will recognize a word while it's being spoken. As an example:

```@example
using Phonetics
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
upt(sample_corpus, [["K", "AA1", "T"]]; inCorpus=true)
```

Here, [K AA1 B] *cob* has a uniqueness point of 2. Looking at the corpus, we can be sure we're looking at *cob* after observing the [AA1] because nothing else begins with the sequence [K AA1]. Thus, its uniqueness point is 2.

```@example
using Phonetics
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
upt(sample_corpus, [["K", "AE1", "D"]]; inCorpus=false)
```

As is evident, given this sample corpus, [K AE1 D] *cad* is unique after the 3rd segment. That is, it can be uniquely identified after hearing the [D].

```@example
using Phonetics
sample_corpus = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]
upt(sample_corpus, [["T", "AE1", "T"]]; inCorpus=false)
```

Here, [T AE1 T] *tat* cannot be uniquely identified until after the sequence is complete, so its uniqueness point is one longer than its length.

## Function documentation

```@docs
pnd(corpus::Array, queries::Array; [progress=true])
```

```@docs
phnprb(corpus::Array, frequencies::Array{Int64}, queries::Array;
    [positional=false, nchar=1, pad=true])
```

```@docs
upt(corpus::Array, queries::Array; [inCorpus=true])
```

## References

Luce, P. A., & Pisoni, D. B. (1998). Recognizing spoken words: The neighborhood activation model. *Ear and hearing, 19*(1), 1.

Vitevitch, M. S., & Luce, P. A. (2016). Phonological neighborhood effects in spoken word perception and production. *Annual Review of Linguistics, 2*, 75-94.