using DataFrames
using ProgressMeter
using Distributed

"""
    lev(s, t)

Levenshtein distance for any iterable, not just strings. Implemented from the
pseudocode on the Wikipedia [page for Levenshtein distance]
(https://en.wikipedia.org/wiki/Levenshtein_distance).

# Parameters
* **s** The first iterable in the comparison; can be a string, Array, tuple,
    etc., so long as it can be indexed
* **t** The second iterable in the comparison; can be a string, Array, tuple,
    etc., so long as it can be indexed

# Returns
* The calculated Levenshtein distance between `s` and `t`
"""
function lev(s, t)
    m = length(s)
    n = length(t)
    d = Array{Int}(zeros(m+1, n+1))

    for i=2:(m+1)
        @inbounds d[i, 1] = i-1
    end

    for j=2:(n+1)
        @inbounds d[1, j] = j-1
    end

    for j=2:(n+1)
        for i=2:(m+1)
            @inbounds if s[i-1] == t[j-1]
                substitutionCost = 0
            else
                substitutionCost = 1
            end
            @inbounds d[i, j] = min(d[i-1, j] + 1, # Deletion
                            d[i, j-1] + 1, # Insertion
                            d[i-1, j-1] + substitutionCost) # Substitution
        end
    end

    @inbounds return d[m+1, n+1]
end

"""
    pnd(corpus::Array, queries::Array; progress=true)

Calculate the phonological neighborhood density (pnd) for each item in `queries`
based on the items in `corpus`. This function uses a vantage point tree data
structure to speed up the search for neighbors by pruning the search space. This
function should work regardless of whether the items in `queries` are in
`corpus` or not.

# Parameters
* **corpus** The corpus to be queried for phonological neighbors
* **queries** The items to query phonological neighbors for in `corpus`
* **progress** Whether to display a progress meter or not

# Returns
* A `DataFrame` with the queries in the first column and the phonological
    neighborhood density in the second
"""
function pnd(corpus::Array, queries::Array; progress=true)

    tree = TextVPTree(corpus, lev)
    results = Vector()
    
    bs = ceil(Int64, length(queries) / nworkers())

    neighbors(query) = length(filter(x -> x != query, radiusSearch(tree, query, 1)))
    
    if progress
        results = @showprogress pmap(neighbors, queries, batch_size=bs)
    else
        results = pmap(neighbors, queries; batch_size=bs)
    end

    return DataFrame(Query=queries, PND=results)
end
