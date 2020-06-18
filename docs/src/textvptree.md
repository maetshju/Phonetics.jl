# Text VP Tree

[A vantage-point tree](https://en.wikipedia.org/wiki/Vantage-point_tree) is a
data structure that takes advantage of the spatial distribution of data and
lets allows for faster searching through the data by lowering the amount of
comparisons that need to be made. Consider the traditional example of
phonological neighborhood density calculation. The code would be written to
compare each item to all the other items. For ``n`` items, there would be
``n-1`` comparisons. So, to calculate the phonological neighborhood density for
each item in a given corpus, there would need to be
``n \times (n-1)\, = \, n^2-n`` comparisons. This is a lot of comparisons!

With a vantage-point tree, however, we might get an average of only needing
``log_2(n)`` comparisons per query because of the way the data are organized.
This means we would only need ``n \times log_2(n)`` comparisons in total, which
can be substantially lower than ``n^2-n`` for larger corpora.

This impelentation is based on the description by Samet (2006).

## Function documentation

```@docs
TextVPTree(items::Array, d::Function)
```

```@docs
radiusSearch(tree::TextVPTree, query, epsilon)
```

```@docs
nneighbors(tree::TextVPTree, query, n)
```

## References

Samet, H. (2006). *Foundations of multidimensional and metric data structures*.
San Francisco, California: Morgan Kaufmann.
