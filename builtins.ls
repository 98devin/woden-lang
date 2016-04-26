
#
# Utility functions
#

# main function to call to push anything to a stack
export push = (item, arr) -->
    console.log "pushing #{typeof! item} to #{JSON.stringify arr}..."
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
    manualpush arity(0) (stack) ->
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

#
# Functions intended to be pushed to the stack
#

export add = arity(2) (a, b) ->
    # addition on numbers
    if typeof! a == typeof! b == \Number
        b + a
    # overload: scanl on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b[til b.length - 1].reverse!reduce ((previous, nextitem) ->
            previous.concat [a nextitem, previous[*-1]]), [b[*-1]]
    # overload: scanr on array, function
    else if typeof! a is \Array and typeof! b is \Function
        a[1 to].reduce ((previous, nextitem) ->
            previous.concat [b nextitem, previous[*-1]]), [a[0]]
            
    
export sub = arity(2) (a, b) ->
    # subtraction on numbers
    if typeof! a == typeof! b == \Number
        b - a
    # overload: filter on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b.filter ->
            push a, [it] .0

export mul = arity(2) (a, b) -> 
    # multiplication on numbers
    if typeof! a == typeof! b == \Number
        b * a
    # overload: fmap on function, array
    else if typeof! a is \Function and typeof! b is \Array
        flatten b.map -> 
            push a, [it]

export div = arity(2) (a, b) ->
    # division on numbers
    if typeof! a == typeof! b == \Number
        b / a
    # overload: reduce on function, array
    else if typeof! a is \Function and typeof! b is \Array
        b[1 to].reduce a, b[0] # TODO: UPDATE THIS!!!
                               # This won't work for fseq or manualpush functions.

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

export drop = manualpush arity(1) (stack) !->
    stack.pop!

export swap = manualpush arity(2) (stack) !->
    a = stack.pop!
    b = stack.pop!
    stack.push a
    stack.push b

export apply = manualpush arity(1) (stack) !->
    push stack.pop!, stack

export incl_range = arity(2) (a, b) ->
    if a > b
        [b to a]
    else
        [b to a by -1]

export pack = manualpush arity(0) (stack) !->
    s = [stack.pop! for til stack.length]
    stack.push s.reverse!

export unpack = manualpush arity(1) (stack) !->
    a = stack.pop!
    for item in a
        stack.push item

export rot = manualpush arity(0) (stack) !->
    stack.splice 0, stack.length, ...rotate 3 1 stack

export length = arity(1) (a) ->
    if typeof! a is \Number
        Math.abs a
    else if typeof! a is \Array
        a.length
    else if typeof! a is \Function
        a.arity

export print = arity(1) (a) ->
    console.log "output >> #{a}"
    console.log ""
    