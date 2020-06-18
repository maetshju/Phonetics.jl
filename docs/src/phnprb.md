# Phonotactic probability

The phonotactic probability is likelihood of observing a sequence in a given
language. It's typically calculated as either the co-occurrence probability of
a series of phones or diphones, or the cumulative transitional probability of
moving from one portion of the sequence to the next.

This package currently provides the co-occurrence method of calculating the
phonotactic probability, and this can be done taking the position of a phone or
diphone into account, or just looking at the co-occurrence probability.

## Examples

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
freq = [1,1,1,1,1,1]
p = prod([4,4,4] / 20)
phnprb(sample_corpus, freq, [["K", "AE1", "T"]])
```

In this example, each phone has 4 observations in the corpus, and the likelihood
of observing each of those phones is 4/20. Because there are 3, the
phonotactic probability of this sequence is ``{\frac{4}{20}}^3``, which is
0.008. Floating point errors sometimes occur in the arithmetic in programming,
but this is unavoidable.

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
freq = [1,1,1,1,1,1]
p = prod([3,2,3,2]/26)
phnprb(sample_corpus, freq, [["K", "AE1", "T"]]; nchar=2)
```

In this example here, the input is padded so that the beginning and ending of
the word are taken into account when calculating the phonotactic probability.
There are 3 counts of [. K] \(where [.] is the word boundary symbol\), 2 counts
of [K AE1], 3 counts of [AE1 T], and 2 counts of [T .]. There are 26 total
diphones observed in the corpus, so the phonotactic probability is calculated
as

```math
\frac{3}{26} \times \frac{2}{26} \times \frac{3}{26} \times \frac{2}{26} \,.
```

## Function documentation

```@docs
phnprb(corpus::Array, frequencies::Array{Int64}, queries::Array;
    positional=false, nchar=1, pad=true)
```
