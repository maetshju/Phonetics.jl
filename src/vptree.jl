using DataStructures
using Statistics

"""
A vantage-point tree. Implemented from Samet, H. (2006). *Foundations of
multidimensional and metric data structures*. San Francisco, California: Morgan
Kaufmann. This data structure allows for searching a metric space in a more
efficient way than comparing all points to each other. The "text" portion of the
name is to imply that this tree will work with text-based data, and, in fact,
is what it was tested to work with. In theory, however, it should work for
numerical data as well.

# Parameters
* **pivot** The pivot point chosen for the tree for a particular node; the
    remaining data points will be assined to either the left or right tree based
    on the median distance between them and this pivot point
* **d** A distance function that will produce a similarity score between two
    data points
* **left** The left subtree containing all the points that are less than the
    median distance away from ``pivot``
* **right** The right subtree containing all the points that are greater than or
    equal to the median distance away from ``pivot``
"""
mutable struct TextVPTree{T}
    pivot::T
    d
    r::Number
    left::TextVPTree{T}
    right::TextVPTree{T}

    """
        TextVPTree{T}(pivot::T, d) where T

    Inner constructor for a `TextVPTree`. There are two methods. The first
    leaves `r` undefined, as would be the case for a leaf node. The other takes
    a value for `r`, which would be used for nodes that aren't leaf nodes.
    """
    function TextVPTree{T}(pivot::T, d) where T
        new(pivot, d)
    end

    function TextVPTree{T}(pivot::T, d, r::Number) where T
        new(pivot, d, r)
    end
end

"""
    TextVPTree(items::Array, d)

Outer constructor for a `TextVPTree`. Takes in an array of items `items` and a
distance function `d` and proceeds to build a vantage-point tree from them.
"""
function TextVPTree(items::Array, d)

    if length(items) == 1 # leaf node
        @inbounds return TextVPTree{typeof(items[1])}(items[1], d)
    end

    # select a pivot
    pivotI = rand(1:length(items))
    @inbounds pivot = items[pivotI]
    @inbounds items = items[1:end .!= pivotI]

    # determine value of r
    distances = [d(pivot, item) for item in items]
    r = median(distances)

    # Assign items to left and right subtrees
    S1 = Vector()
    S2 = Vector()
    for (item, dist) in zip(items, distances)
        if dist < r
            push!(S1, item)
        else
            push!(S2, item)
        end
    end

    # create tree
    tree = TextVPTree{typeof(pivot)}(pivot, d, r)

    # recursively define left and right subtrees
    if length(S1) > 0
        tree.left = TextVPTree(S1, d)
    end

    if length(S2) > 0
        tree.right = TextVPTree(S2, d)
    end

    return tree
end

"""
    radiusSearch(tree::TextVPTree, query, epsilon)

Performs a search for all items in a VP tree `tree` that are within a radius
`epsilon` from a query `query`.

# Returns

A `Vector` of items that are within the given radius `epsilon`
"""
function radiusSearch(tree::TextVPTree, query, epsilon)

    results = Vector()
    d = tree.d
    r = isdefined(tree, :r) ? tree.r : -1
    p = tree.pivot
    q = query

    # add root node if possible
    if q != p && d(q, p) <= epsilon
        push!(results, p)
    end

    # at leaf node, so can't recurse any further
    if r == -1
        return results
    end

    # check if we need to recurse into left and right subtrees using
    # inequalities from the implementation text
    if isdefined(tree, :left) && max(d(q, p) - r, 0) <= epsilon
        results = vcat(results, radiusSearch(tree.left, query, epsilon))
    end

    if isdefined(tree, :right) && max(r - d(q, p), 0) <= epsilon
        results = vcat(results, radiusSearch(tree.right, query, epsilon))
    end

    return results
end

"""
    nneighbors(tree::TextVPTree, query, n)

Find the `n` nearest neighbors in a VP tree `tree` to a given query `query`.

# Returns

* A `PriorityQueue` of items where the keys are the items themselves and the values are the distances from the items to `query`; the `PriorityQueue` is defined such that small values have higher priorities than large ones
"""
function nneighbors(tree::TextVPTree, query, n)

    # Helper function that adds items to the `PriorityQueue` that will
    # eventually be returned
    function nneighbors_(tree::TextVPTree, query, n, pq)

        d = tree.d
        r = isdefined(tree, :r) ? tree.r : -1
        p = tree.pivot
        q = query

        # if the `PriorityQueue` is not yet full, add the item
        # otherwise, add the item if it's closer to `query` than the furthest
        # item in `pq`
        if length(pq) < n && ! haskey(pq, p) && p != q
            enqueue!(pq, p=>d(p, q))
        elseif d(p, q) < peek(pq)[2] && ! haskey(pq, p) && p != q
            enqueue!(pq, p=>d(p, q))
            dequeue!(pq)
        end

        # check if the left subtree may contain items closer to `query` than
        # are in the queue; if so, check the left subtree for neighbors
        if isdefined(tree, :left)
            rlo = 0
            rhi = r
            d1 = max(d(q, p) - rhi, rlo - d(q, p), 0)

            if length(pq) < n || d1 <= peek(pq)[2]
                pq = nneighbors_(tree.left, q, n, pq)
            end
        end

        # check if the right subtree may contain items closer to `query` than
        # are in the queue; if so, check the right subtree for neighbors
        if isdefined(tree, :right)
            rlo = r
            rhi = Inf
            d1 = max(d(q, p) - rhi, rlo - d(q, p), 0)

            if length(pq) < n || d1 <= peek(pq)[2]
                pq = nneighbors_(tree.right, q, n, pq)
            end
        end

        return pq
    end

    d = tree.d
    r = isdefined(tree, :r) ? tree.r : -1
    p = tree.pivot
    q = query

    # if this first element is not the same as `query`, add it to `pq`
    # otherwise, instantiate `pq` as an empty `PriorityQueue`
    local pq
    if q != p
        pq = PriorityQueue(Base.Order.Reverse, p=>d(p, q))
    else
        pq = PriorityQueue(Base.Order.Reverse)
    end

    # check if the left subtree may contain items closer to `query` than
    # are in the queue; if so, check the left subtree for neighbors
    if isdefined(tree, :left)
        rlo = 0
        rhi = r
        d1 = max(d(q, p) - rhi, rlo - d(q, p), 0)

        if length(pq) < n || d1 <= peek(pq)[2]
            pq = nneighbors_(tree.left, q, n, pq)
        end
    end

    # check if the right subtree may contain items closer to `query` than
    # are in the queue; if so, check the right subtree for neighbors
    if isdefined(tree, :right)
        rlo = r
        rhi = Inf
        d1 = max(d(q, p) - rhi, rlo - d(q, p), 0)

        if length(pq) < n || d1 <= peek(pq)[2]
            pq = nneighbors_(tree.right, q, n, pq)
        end
    end

    return pq
end
