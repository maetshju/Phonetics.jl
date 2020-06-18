# Phonological neighborhood density

Phonological neighborhood density, as described by Luce & Pisoni (1998), as a concept is a set of words that sound similar to each other. Vitevitch & Luce (2016) explain that it's common to operationalize this concept as the number of words that have a Levenshtein distance (minimal number of segment additions, subtractions, or substitutions to transform one word or string into another) of exactly 1 from the word in question.

The `pnd` function allows a user to calculate this value for a list of words based on a given corpus. The following example shows how to use the `pnd` function. Note that the entries in the sample corpus are given using the Arpabet transcription scheme.

```@example
using LexicalCharacteristics
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

## Example: Calculating the phonological neighborhood density for each item in the CMU Pronouncing Dictionary

This is a more likely research-scenario. For the purposes of this example, I'll assume you have already downloaded the [CMU Pronouncing Dictionary](http://www.speech.cs.cmu.edu/cgi-bin/cmudict). There is a bit of extra information at the top of the document that needs to be deleted, so make sure the first line in the document is the entry for "!EXCLAMATION-POINT".

Now, the first thing we need to do is read the file into Julia and process it into a usable state. Because we're interested in the phonological transcriptions here, we'll strip away the orthographic representation.

```julia
using LexicalCharacteristics
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

## Implementation note

The intuitive way of coding phonological neighborhood density involves comparing every item in the corpus against every other item in the corpus and counting how many neighbors each item has. However, this is computationally inefficient, as there are approximately ``n^2`` comparisons that must be performed. In this package, this process is sped up by using a spatial data structure called a [vantage-point tree](https://en.wikipedia.org/wiki/Vantage-point_tree). This data structure is a binarily branching tree where all the items on the left of a node are less than a particular distance away from the item in the node, and all those on the right are greater than or equal to that particular distance.

Because of the way that the data is organized in a vantage-point tree, fewer comparisons need to be made. While descending the tree, it can be determined whether any of the points in a branch from a particular node should be searched or not, limiting the number of branches that need to be traversed. In practical terms, this means that the Levenshtein distance is calculated fewer times for each item, and the phonological neighborhood density should be calculated faster for a data set than from using the traditional approach that compares each item to all the other ones in the corpus. At the time of writing this document, I am not aware of any phonological neighborhood density calculator/script that offers this kind of speedup.

## Function documentation

```@docs
pnd(corpus::Array, queries::Array)
```

## References

Luce, P. A., & Pisoni, D. B. (1998). Recognizing spoken words: The neighborhood activation model. *Ear and hearing, 19*(1), 1.

Vitevitch, M. S., & Luce, P. A. (2016). Phonological neighborhood effects in spoken word perception and production. *Annual Review of Linguistics, 2*, 75-94.
