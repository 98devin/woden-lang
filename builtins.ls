
#
# Utility functions
#

# main function to call to push anything to a stack
export push = (item, arr) -->
    if typeof! item is \Function and arr.length >= (item.arity ? 0)
        if item.manualpush
            item arr
        else
            arr.push item ...[arr.pop! for til item.arity]
    else
        arr.push item
    arr

export cycle = (amount, arr) -->
    real_amt = amount % arr.length
    if real_amt is 0
        arr
    else if real_amt < 0
        cycle real_amt, arr.reverse! .reverse!
    else
        arr[real_amt to] ++ arr[til real_amt]

export rotate = (depth, amount, arr) -->
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
    manualpush arity(0) (stack) !->
        for item in sequence
            push item, stack

flatten = (arr) ->
    res = []
    for item in arr
        if typeof! item is \Array
            res = res.concat item
        else
            res.push item
    res

deep-flatten = (arr) ->
    res = []
    for item in arr
        if typeof! item is \Array
            res = res.concat deep-flatten item
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

export add = arity(2) (a, b) ->
    # addition on numbers
    if typeof! a == typeof! b == \Number
        b + a
    # overload: scanr on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b[til b.length - 1].reverse!reduce ((previous, nextitem) ->
            previous.concat push a, [previous[*-1], nextitem]), [b[*-1]]
    # overload: scanl on array, function
    else if typeof! a is \Array and typeof! b is \Function
        a[1 to].reduce ((previous, nextitem) ->
            previous.concat push b, [previous[*-1], nextitem]), [a[0]]


export sub = arity(2) (a, b) ->
    # subtraction on numbers
    if typeof! a == typeof! b == \Number
        b - a
    # overload: filter on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b.filter ->
            truthy(push a, [it] .0) # only first element of result is checked
    # overload: filter on array, function
    else if typeof! a is \Array and typeof! b is \Function
        a.filter ->
            truthy(push b, [it] .0) # only first element of result is checked

export mul = arity(2) (a, b) ->
    # multiplication on numbers
    if typeof! a == typeof! b == \Number
        b * a
    # overload: fmap on function, array
    else if typeof! a is \Function and typeof! b is \Array
        flatten b.map ->
            push a, [it]
    # overload: fmap on array, function
    else if typeof! a is \Array and typeof! b is \Function
        flatten a.map ->
            push b, [it]

export div = arity(2) (a, b) ->
    # division on numbers
    if typeof! a == typeof! b == \Number
        b / a
    # overload: foldr on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b[til b.length - 1].reverse!reduce((prev, val) ->
            push a, (push val, prev)
        , [b[*-1]])
    # overload: foldl on array, function
    else if typeof! a is \Array and typeof! b is \Function
        a[1 to].reduce((prev, val) ->
            push b, (push val, prev)
        , [a[0]])

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

export pack = manualpush arity(0) (stack) !->
    # packs up the current stack and pushes it as an array
    s = [stack.pop! for til stack.length]
    stack.push s.reverse!

export unpack = manualpush arity(1) (stack) !->
    a = stack.pop! # an array whose contents you want on the stack
    return a if typeof! a isnt \Array
    for item in a
        stack.push item # note that nothing is applied

export rot = manualpush arity(0) (stack) !->
    # cycles the third item from the top to the front of the stack
    stack.splice 0, stack.length, ...rotate 3 1 stack

export length = arity(1) (a) ->
    if typeof! a is \Number
        Math.abs a
    else if typeof! a is \Array
        a.length
    else if typeof! a is \Function
        a.arity

export join = arity(2) (a, b) ->
    if typeof! a isnt \Array and typeof! b isnt \Array
        [b, a]
    else if typeof! a is \Array and typeof! b isnt \Array
        a.unshift b
        a
    else if typeof! a isnt \Array and typeof! b is \Array
        b.push a
        b

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
    return take(-a, b.reverse!).reverse! if a < 0
    b[til Math.floor(a)]

export drop = arity(2) (a, b) ->
    return drop(-a, b.reverse!).reverse! if a < 0
    b[Math.floor(a) to]

export bit-select = arity(2) (a, b) ->
    if typeof! a is \Number
        a = Math.floor(a).to-string(2).split("").reverse!reduce((prev, val, i) ->
            prev.push i if val != "0"
            prev
        , [])
    if typeof! b is \Number
        b = Math.floor(b).to-string(2).split("").reverse!reduce((prev, val, i) ->
            prev.push i if val != "0"
            prev
        , [])
    [b[i] for i in a when i < b.length]
