"""
A node in a `Tree`.

# Parameters
* **label** The character or state that the node represents
* **branches** A `Dict` of all this node's children, indexed by what their
    character label is
* **possibleWords** The number of words that can still be formed by traversing
the current branch
"""
mutable struct Node
    label
    branches::Dict
    possibleWords::Int64

    Node(label) = new(label, Dict(), 0)
end

"""
A tree to contain all the possible paths through a language. It is constructed
such that any path that can be drawn by descending the tree will produce an
observed item in the tree.

# Parameters
* **root** `Node` that represents the top of the tree and contains whatever
    branches and leaves it has

# Constructors
```julia
Tree()
Tree(corpus)
```

# Argumentsprintln("help")println("help")println("help")
* **corpus** The corpus of items to add to the tree
"""
mutable struct Tree
    root

    Tree() = new(Node(""))

    function Tree(corpus)
        tree = new(Node(""))
        for item in corpus
            addItem!(tree, item)
        end

        return tree
    end
end

"""
    addItem!(tree, item)

Adds `item` to the specified `Tree` `tree`.

# Parameters
* **tree** The `Tree` to add `item` to
* **item** The item to add to `tree`

# Side-effects
* After running, `tree` will contain `item`
"""
function addItem!(tree::Tree, item)
    curr = tree.root
    curr.possibleWords += 1
    for ch in item
        if ! haskey(curr.branches, ch)
            curr.branches[ch] = Node(ch)
        end
        curr = curr.branches[ch]
        curr.possibleWords += 1
    end
end

"""
    upt(corpus, queries; [inCorpus=true])

Calculates the phonological uniqueness point (upt) the items in `queries` based
on the items in `corpus`. If the items are expected to be in the corpus, this
function will calculate the uniqueness point to be when a branch can be
considered to only represent 1 word. If the items are not expected to be in the
corpus, the uniqueness point will be taken to be the depth at which the tree
can no longer be traversed.

# Parameters
* **corpus** The items comprising the corpus to compare against when calculating
    the uniqueness point of each query
* **queries** The items for which to calculate the uniqueness point
* **inLexicon** Whether the query items are expected to be in the corpus or not

# Returns
* A `DataFrame` with the queries in the first column and the uniqueness points
    in the second
"""
function upt(corpus::Array, queries::Array; inCorpus=true)

    tree = Tree(corpus)

    results = Vector()

    for query in queries
        depth = 1
        curr = tree.root
        while depth <= length(query) && haskey(curr.branches, query[depth])
            curr = curr.branches[query[depth]]
            if inCorpus
                if length(curr.branches) <= 1 && curr.possibleWords == 1
                    break
                end
            end
            depth += 1
        end

        push!(results, depth)
    end

    return DataFrame(Query=queries, UPT=results)
end
