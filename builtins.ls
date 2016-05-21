

#
# Utility functions
#


# main function to call to push anything to a stack
export push = (item, arr) -->
    if type(item) is \Function and arr.length >= (item.arity ? 0)
        if item.manualpush
            item arr
        else
            arr.push item ...[arr.pop! for til item.arity]
    else
        arr.push item
    arr

cycle = (amount, arr) -->
    real_amt = amount % arr.length
    if real_amt is 0
        arr
    else if real_amt < 0
        cycle real_amt, arr.reverse! .reverse!
    else
        arr[real_amt to] ++ arr[til real_amt]

rotate = (depth, amount, arr) -->
    if depth is 0
        arr
    else if depth < 0
        rotate -depth, -amount, arr.reverse! .reverse!
    else if depth >= arr.length
        cycle amount, arr
    else
        arr[til arr.length - depth] ++ cycle amount, arr[arr.length - depth to]

# decorator-ish thing to set manual stack control
manualpush = (f) ->
    f.manualpush = true
    f

# decorator-ish thing to set arity of a function
arity = (ar, f) -->
    f.arity = ar
    f

# function for generating stack push sequences
export fseq = (sequence) ->
    f = manualpush arity(0) (stack) !->
        for item in sequence
            if !item.is-fseq      # do not apply internal fseqs when pushing.
                push item, stack  # this is to allow for proper nesting.
            else                  # otherwise, {x} is functionally identical to {{x}}
                stack.push item
    f.is-fseq = true
    f

flatten = (arr) ->
    res = []
    for item in arr
        if type(item) is \Array
            res .= concat item
        else
            res.push item
    res

deep-flatten = (arr) ->
    res = []
    for item in arr
        if type(item) is \Array
            res .= concat deep-flatten item
        else
            res.push item
    res

truthy = (thing) ->
    | thing == 0    => false
    | thing == null => false
    | otherwise     => true


#
# Functions intended to be pushed to the stack
#


export type = arity(1) (a) ->
    a?.constructor?.name ? \Null

export add = arity(2) (a, b) ->
    # addition on numbers
    if type(a) == type(b) == \Number
        b + a
    # overload: scanr on function, array
    else if type(a) is \Function and type(b) is \Array
        b[til b.length - 1].reverse!reduce ((previous, nextitem) ->
            previous.concat push a, [previous[*-1], nextitem]), [b[*-1]]
    # overload: scanl on array, function
    else if type(a) is \Array and type(b) is \Function
        a[1 to].reduce ((previous, nextitem) ->
            previous.concat push b, [previous[*-1], nextitem]), [a[0]]


export sub = arity(2) (a, b) ->
    # subtraction on numbers
    if type(a) == type(b) == \Number
        b - a
    # overload: filter on function, array
    else if type(a) is \Function and type(b) is \Array
        b.filter ->
            truthy(push a, [it] .0) # only first element of result is checked
    # overload: filter on array, function
    else if type(a) is \Array and type(b) is \Function
        a.filter ->
            truthy(push b, [it] .0) # only first element of result is checked
    # overload: filter on function, sequence
    else if type(a) is \Function and type(b) is \Sequence
        b.add-transform {
            type: \filter
            func: a
        }
        b


export mul = arity(2) (a, b) ->
    # multiplication on numbers
    if type(a) == type(b) == \Number
        b * a
    # overload: fmap on function, array
    else if type(a) is \Function and type(b) is \Array
        flatten b.map ->
            push a, [it]
    # overload: fmap on array, function
    else if type(a) is \Array and type(b) is \Function
        flatten a.map ->
            push b, [it]
    # overload: fmap on function, sequence
    else if type(a) is \Function and type(b) is \Sequence
        b.add-transform {
            type: \map
            func: a
        }
        b

export div = arity(2) (a, b) ->
    # division on numbers
    if type(a) == type(b) == \Number
        b / a
    # overload: foldr on function, array
    else if type(a) is \Function and type(b) is \Array
        b[til b.length - 1].reverse!reduce((prev, val) ->
            push a, push val, prev
        , [b[*-1]])[*-1] # TODO: something about this, maybe
    # overload: foldl on array, function
    else if type(a) is \Array and type(b) is \Function
        a[1 to].reduce((prev, val) ->
            push b, push val, prev
        , [a[0]])[*-1]   # TODO: something about this, maybe

export mod = arity(2) (a, b) -> b % a

export exp = arity(2) (a, b) -> b ^ a

export gt  = arity(2) (a, b) ->
    if b > a then 1 else 0

export lt  = arity(2) (a, b) ->
    if b < a then 1 else 0

export eq  = arity(2) (a, b) ->
    if b is a then 1 else 0

export dup = manualpush arity(1) (stack) ->
    top = stack.pop!
    stack.push top
    stack.push top

export drop1 = manualpush arity(1) (stack) !->
    stack.pop!

export swap = manualpush arity(2) (stack) !->
    a = stack.pop!
    b = stack.pop!
    stack.push a
    stack.push b

export apply = manualpush arity(1) (stack) !->
    # re-push an item using the push function.
    # this means an fseq will be guaranteed to be applied.
    push stack.pop!, stack

export incl-range = arity(2) (a, b) ->
    if a > b
        [b to a]
    else
        [b to a by -1]

export unary-range = arity(1) (a) ->
    if type(a) is \Number
        if a >= 0
            [0 til a]
        else
            [0 til a by -1]

export pack = manualpush arity(0) (stack) !->
    # packs up the current stack and pushes it as an array
    s = [stack.pop! for til stack.length]
    stack.push s.reverse!

export unpack = manualpush arity(1) (stack) !->
    a = stack.pop! # an array whose contents you want on the stack
    return a if type(a) isnt \Array
    for item in a
        stack.push item # note that nothing is applied

export rot = manualpush arity(0) (stack) !->
    # cycles the third item from the top to the front of the stack
    stack.splice 0, stack.length, ...rotate 3 1 stack

export length = arity(1) (a) ->
    if type(a) is \Number
        Math.abs a
    else if type(a) is \Array or type(a) is \Sequence
        a.length
    else if type(a) is \Function
        a.arity

export concat = arity(2) (a, b) ->
    if type(a) isnt \Array and type(b) isnt \Array
        [b, a]
    else if type(a) is \Array and type(b) isnt \Array
        [b, ...a]
    else if type(a) isnt \Array and type(b) is \Array
        [...b, a]
    else if type(a) == type(b) == \Array
        b ++ a

export repeat = manualpush arity(2) (stack) !->
    a = stack.pop! # number of times to repeat
    b = stack.pop! # the thing to repeat
    for til a
        push b, stack

export while-loop = manualpush arity(2) (stack) !->
    a = stack.pop! # loop condition
    b = stack.pop! # item to push while the condition is true
    loop
        push a, stack
        result = stack.pop! # note that the result is consumed
        if result
            push b, stack
        else break

export take = arity(2) (a, b) ->
    if type(b) is \Array
        return b if Math.abs(a) >= b.length # small optimization
        return take(-a, b.reverse!).reverse! if a < 0
        b[til Math.floor(a)]
    else if type(b) is \Sequence
        b.ensure-length(Math.floor(a))
        b.seq[til Math.floor(a)]

export drop = arity(2) (a, b) ->
    if type(b) is \Array
        return [] if Math.abs(a) >= b.length # small optimization
        return drop(-a, b.reverse!).reverse! if a < 0
        b[Math.floor(a) to]
    else if type(b) is \Sequence
        b.ensure-length(Math.floor(a))
        b.seq = []
        b

export bit-select = arity(2) (a, b) ->
    # selects particular indices of an array using an array of indices or a number's bits
    if type(a) is \Number
        a = Math.floor(a).to-string(2).split("").reverse!reduce((prev, val, i) ->
            prev.push i if val != "0"
            prev
        , [])
    if type(b) is \Number
        b = Math.floor(b).to-string(2).split("").reverse!reduce((prev, val, i) ->
            prev.push i if val != "0"
            prev
        , [])
    if type(b) is \Array
        [b[i] for i in a when i < b.length]
    else if type(b) is \Sequence
        [b.get(i) for i in a]

# a data structure representing lazily-generated infinite sequences
export class Sequence
    (@get-next, @base-seq = [0]) ~>
        @transforms = [] # should contain {type, func} objects with type = 'filter' or 'map'
        @seq = []        # the sequence, filtered and mapped
        @base-pos = 0    # the element being accessed by the transform processor
        @length = 0

    to-JSON: -> "[...]"

    get: (index) ->
        @ensure-length(index + 1)
        @seq[index]

    lengthen-base-seq: ->
        #console.log "base: #{JSON.stringify @base-seq}"
        #console.log "seq:  #{JSON.stringify @seq}"
        @base-seq.push (push @get-next, ^^@base-seq)[*-1]

    add-transform: (transform) ->
        # adds and applies a new map or filter operation over the sequence;
        # this affects all future values of the sequence as you'd expect
        switch transform.type
        case \filter
            @seq = sub(transform.func, @seq)
            @length = @seq.length
            @transforms.push transform
        case \map
            @seq = mul(transform.func, @seq)
            @length = @seq.length
            @transforms.push transform

    ensure-length: (desired-length) !->
        # ensures that the sequence contains at least `desired-length` elements
        :main until @seq.length >= desired-length
            @lengthen-base-seq!
            item = [@base-seq[@base-pos]]
            for transform in @transforms
                switch transform.type
                case \filter
                    unless truthy (push transform.func, ^^item)[*-1]
                        @base-pos++
                        continue main
                case \map
                    item = push transform.func, item
            @seq .= concat item
            @base-pos++
            @length = @seq.length

export sequence1 = arity(1) (a) ->
    # constructs a sequence with initial base sequence of [0] by default
    Sequence a

export sequence2 = arity(2) (a, b) ->
    # constructs a sequence using `b` as the initial base sequence
    Sequence a, b

export elem = arity(2) (a, b) ->
    # takes the `a`-th element of `b`
    if type(b) is \Array
        b[a]
    else if type(b) is \Sequence
        b.get(a)
