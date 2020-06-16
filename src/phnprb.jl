using DataFrames

"""
    padItem(item, nchar)

Pads an item with an appropriate amount of "." characters so that n-grams can be
created. Provides two methods:

    padItem(item::Array{String}, nchar::Integer)
    padItem(item::String, nchar::Integer)

# Arguments
* **item** The item that needs to be padded; may be an `Array` of `Strings` or
    simply a `String`
* **nchar** The number of characters contained in the n-gram that is being
    examined (e.g., 2 for diphones)

# Returns
The item with appropriate padding
"""
function padItem(item::Array{String}, nchar::Integer)
    padding = ["." for x in 1:(nchar-1)]
    item = vcat(padding, item, padding)
    return item
end

function padItem(item::String, nchar::Integer)
    padding = repeat(".", nchar-1)
    item = padding * item * padding
    return item
end

"""
    createGrams(item, nchar::Integer)

Creates the n-grams that will be analyzed. If looking at diphones, will produce
diphones from the input, for example. Here, n-grams is used in a general sense
as an extension of the n-gram in natural language processing.

# Arguments
* **item** The item for which to create the list of n-grams
* **nchar** The number of characters for each gram (e.g., 2 for diphones)

# Returns
A `Vector` of the created n-grams
"""
function createGrams(item, nchar::Integer)
    grams = Vector()
    for i=1:(length(item)-(nchar-1))
        push!(grams, item[i:i+(nchar-1)])
    end
    return grams
end

"""
    countSymbols(corpus::Array, frequencies::Array, positional::Bool,
        nchar::Integer, pad::Bool)

Counts the number of occurrences of each symbol in the passed in corpus;
produces, for example, the number of times "K" appears in the corpus.

# Arguments
* **corpus** The corpus from which to derive the counts
* **frequencies** The number of times each item in the corpus has been observed;
    this variable must correspond with `corpus` such that the n-th element of
    `corpus` is related to the n-th element of `frequencies`.
* **positional** Whether to consider where in a word a given phone appears
(e.g., should "K" as the first sound be considered a different category than "K"
    as the second sound?)
* **nchar** The number of characters for each n-gram that will be examined
    (e.g., 2 for diphones)
* **pad** Whether to add padding to each query or not

# Returns
A `Dict` where each key is a differnt observed "gram," and each paired value is
the number of times that n-gram was observed
"""
function countSymbols(corpus::Array, frequencies::Array, positional::Bool,
    nchar::Integer, pad::Bool)

    counts = Dict()
    total = 0

    for item in corpus

        if pad
            item = padItem(item, nchar)
        end
        item = createGrams(item, nchar)

        for (i, ch) in enumerate(item)

            key = positional ? (i, ch) : ch

            if haskey(counts, key)
                counts[key] += frequencies[i]
            else
                counts[key] = frequencies[i]
            end

            total += 1
        end
    end

    return counts
end

"""
    calcProb(counts, query, positional, total)

Calculates the phonotactic probability for a query by determining the count of
each n-gram contained in the query, dividing each count by the total number of
n-grams observed in the corpus, and taking the product of those proportions

# Arguments
* **counts** A `Dict` that can be indexed with n-grams and produce the number
    of occurrences for that item
* **query** The item for which the phonotactic probability should be calculated
* **positional** Whether to consider where in the query a given phone appears
    (e.g., should "K" as the first sound be considered a different category
    than "K" as the second sound?)

# Returns
The calculated phonotactic probability for the given query item
"""
function calcProb(counts::Dict, query, positional::Bool, total)
    unitCounts = Int64[]

    for (i, ch) in enumerate(query)

        key = positional ? (i, ch) : ch

        if haskey(counts, key)
            push!(unitCounts, counts[key])
        else
            push!(unitCounts, 0)
        end
    end

    return prod(unitCounts / total)
end

"""
    phnprb(corpus::Array, frequencies::Array, queries::Array; positional=false,
        nchar=1, pad=true)

Calculates the phonotactic probability for each item in a list of queries based
on a corpus

# Arguments
* **corpus** The corpus on which to base the probability calculations
* **frequencies** The frequencies associated with each element in `corpus`
* **queries** The items for which the probability should be calculated

## Keyword arguments
* **positional**  Whether to consider where in the query a given phone appears
(e.g., should "K" as the first sound be considered a different category than "K"
    as the second sound?)
* **nchar** The number of characters for each n-gram that will be examined
    (e.g., 2 for diphones)
* **pad** Whether to add padding to each query or not

# Returns
A `DataFrame` with the queries in the first column and the probability values
    in the second
"""
function phnprb(corpus::Array, frequencies::Array{Int64}, queries::Array;
    positional=false, nchar=1, pad=true)

    counts = countSymbols(corpus, frequencies, positional, nchar, pad)
	total = sum(values(counts))

    results = Vector()
	
    for query in queries
        local paddedQuery
        if pad
            paddedQuery = padItem(query, nchar)
        else
            paddedQuery = query
        end
        grams = createGrams(paddedQuery, nchar)
        prob = calcProb(counts, grams, positional, total)
        push!(results, prob)
    end

    return DataFrame(Query=queries, Probability=results)
end
