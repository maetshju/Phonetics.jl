# Uniqueness point

The uniqueness point of a word is defined as the segment in a sequence after which that sequence can be uniquely identified. In cohort models of speech perception, it is after this point that a listener will recognize a word while it's being spoken.

## Examples

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
upt(corpus::Array, queries::Array; inCorpus=true)
```
