


#
# Utility functions, used only internally or by the interpreter
#



# main function to call to push anything to a stack
export push = (item, arr) -->
    return arr if item is null
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
arity = (ar, f) ->
    f.arity = ar
    f

# function for generating stack push sequences
export fseq = (sequence) ->
    f = manualpush arity 0 (stack) !->
        for item in sequence
            if !item.is-fseq      # do not apply internal fseqs when pushing.
                push item, stack  # this is to allow for proper nesting.
            else                  # otherwise, {x} is functionally identical to {{x}}
                stack.push item
    f.is-fseq = true
    f.seq = sequence
    f

# function for getting some interpreter functionality on the stack.
# it needs a reference to the evaluation function and the values to push
export mega-fseq = (evaluate, values, AST, ENV) ->
    manualpush arity 0 (stack) !->
        for node in values
            evaluate(node, stack, AST, ENV) # that oughta do it better

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

export truthy = ->
    switch it
    case 0            => false
    case null, false  => false
    else              => true


# RUNES HAVE BEEN ABOLISHED IN THE NEW INTERPRETER
# THEIR FUNCTIONALITY WILL REMAIN IN THE FORM OF OTHER BUILT-INS OR REGULAR FUNCTIONS



#
# Functions which can be pushed to the stack
#


# Any
export type = arity 1 (a) ->
    a?.constructor.name ? \Null

# Number, Number
add = arity 2 (a, b) -> a + b

# Function, Array
scanr = arity 2 (a, b) ->
    b[til b.length - 1].reverse!reduce ((previous, nextitem) ->
        previous.concat push a, [previous[*-1], nextitem]), [b[*-1]]

# Function, Array
scanl = arity 2 (a, b) -> 
    b[1 to].reduce ((previous, nextitem) ->
        previous.concat push a, [previous[*-1], nextitem]), [b[0]]

# Number, Number
sub = arity 2 (a, b) -> b - a

# Function, Array
filter = arity 2 (a, b) ->
        b.filter ->
            truthy(push a, [it] .0) # only first element of result is checked

# Number, Number
mul = arity 2 (a, b) -> b * a

# Function, Array
fmap = arity 2 (a, b) ->
    flatten b.map ->
        push a, [it]

# Number, Number
div = arity 2 (a, b) -> b / a

# Function, Array
foldr = arity 2 (a, b) ->
    b[til b.length - 1].reverse!reduce((prev, val) ->
        push a, push val, prev
    , [b[*-1]])[*-1] # TODO: something about this, maybe
    
# Function, Array
foldl = arity 2 (a, b) ->
    b[1 to].reduce((prev, val) ->
        push a, push val, prev
    , [b[0]])[*-1]   # TODO: something about this, maybe

# Number, Number
mod = arity 2 (a, b) -> b % a

# Number, Number
exp = arity 2 (a, b) -> b ^ a

# Number, Number
# Array, Array ?
gt = arity 2 (a, b) ->
    if b > a then 1 else 0

# Number, Number
# Array, Array ?
lt = arity 2 (a, b) ->
    if b < a then 1 else 0

# Any, Any
eq = arity 2 (a, b) ->
    return 1 if a is b
    return 0 if type(a) != type(b)
    if type(a) is \Array
        return 0 if a.length != b.length
        for i til a.length
            return 0 unless eq(a[i], b[i])
        return 1
    else if type(a) is \Function
        return 0 unless a.is-fseq and b.is-fseq
        return eq(a.seq, b.seq)
    return 0

# Any
export apply = manualpush arity 1 (stack) !->
    # re-push an item using the push function.
    # this means an fseq will be guaranteed to be applied.
    push stack.pop!, stack

# Number, Number
incl-range = arity 2 (a, b) ->
    if a > b
        [b to a]
    else
        [b to a by -1]

# Number
unary-range = arity 1 (a) ->
    if a >= 0
        [0 til a]
    else
        [0 til a by -1]

# Any...
pack = manualpush arity 0 (stack) !->
    # packs up the current stack and pushes it as an array
    s = [stack.shift! for til stack.length]
    stack.push s

# Array
unpack = manualpush arity 1 (stack) !->
    a = stack.pop! # an array whose contents you want on the stack
    for item in a
        stack.push item # note that nothing is applied

# Any...
rot = manualpush arity 0 (stack) !->
    # cycles the third item from the top to the front of the stack
    stack.splice 0, stack.length, ...rotate 3, 1, stack

# Number
abs = arity 1 (a) -> Math.abs a

# Array
length = arity 1 (a) -> a.length
    
# Function
get-arity = arity 1 (a) -> a.arity

# Any, Any
concat = arity 2 (a, b) ->
    if type(a) isnt \Array and type(b) isnt \Array
        [b, a]
    else if type(a) is \Array and type(b) isnt \Array
        [b, ...a]
    else if type(a) isnt \Array and type(b) is \Array
        [...b, a]
    else if type(a) == type(b) == \Array
        b ++ a

# Number, Any
repeat = manualpush arity 2 (stack) !->
    a = stack.pop! # number of times to repeat
    b = stack.pop! # the thing to repeat
    for til a
        push b, stack # note that `b` is applied each time

# Number, Array
take = arity 2 (a, b) ->
    # returns the first `a` elements of `b`, or b[0..a] if a > b.length
    return [] if a == 0
    return b if Math.abs(a) >= b.length
    return drop(b.length + a, b) if a < 0
    b[til Math.floor(a)]

# Number, Array
drop = arity 2 (a, b) ->
    # removes the first `a` elements of `b`, returning b or [] if a > b.length
    return b if a == 0
    return [] if Math.abs(a) >= b.length
    return take(b.length + a, b) if a < 0
    b[Math.floor(a) to]

# Number, Array
elem = arity 2 (a, b) ->
    # takes the `a`-th element of `b`
    if type(b) is \Array
        b[a]

# Number
neg = arity 1 (a) -> -a

# Array
reverse = arity 1 (a) -> a.reverse!



#
# Functions to help interfacing with the interpreter environment
#



# decorator-ish thing to set input types of a function.
# this only has an effect when generating the builtin core
# if a certain type shouldn't be checked, use `null` in the list.
# this function allows builtin functions to be interpreted with checked types.
# overloads are not strictly possible with `takes`, but trivial to make in the language itself.
takes = (typelist, f) -->
    f.type-req = typelist
    f


# function to create the nesting structure needed to import
# builtin functions into the interpreter.
# ENV can be supplied to supplement an existing environment
make-environment = (env-dict, ENV={}) ->
    for key of env-dict
        builtin-f = env-dict[key] # the builtin function
        arity = builtin-f.arity ? 0
        types = builtin-f.type-req ? [null for til arity]
        param-counter = 0
        params = for let type in types
            { 
                anonymous: true 
                type: type # set to null for no checking
                name: param-counter++ # all parameters are anonymous of course 
            }
        func = {
            type: \function
            name: key
            params: params
            typechecks: types.filter((x) -> x != null).length
            valuechecks: 0
            arity: builtin-f.arity
            value: [{
                type: \native-function
                value: builtin-f
            }]
        }
        if key of ENV
            ENV[key].overloads.push func
        else
            ENV[key] = {
                type: \function
                name: key
                overloads: [func]
            }
    return ENV

export get-environment = (extended=false, ENV={}) ->
    make-environment(core-basic, ENV)
    if extended
        make-environment(core-extra, ENV)
    return ENV

# the most basic functionality, not able to be implemented within Woden
core-basic = {
    "+": takes ["Number", "Number"], add
    "-": takes ["Number", "Number"], sub
    "*": takes ["Number", "Number"], mul
    "/": takes ["Number", "Number"], div
    "%": takes ["Number", "Number"], mod
    "^": takes ["Number", "Number"], exp
    "<": takes ["Number", "Number"], lt
    ">": takes ["Number", "Number"], gt
    "=": eq
    "apply": apply
    "join": concat
    "elem": takes ["Number", "Array"], elem
    "drop": takes ["Number", "Array"], drop
    "take": takes ["Number", "Array"], take
    "length": takes ["Array"], length
    "reverse": takes ["Array"], reverse
}

# an extension dictionary of more functionality for convenience.
# these functions can mostly be written within Woden, but these versions
# are potentially faster (and easier to start using, of course)
core-extra = {
    "range": takes ["Number", "Number"], incl-range
    "iota": takes ["Number"], unary-range
    "scanr": takes ["Function", "Array"], scanr
    "scan": takes ["Function", "Array"], scanl
    "filter": takes ["Function", "Array"], filter
    "fmap": takes ["Function", "Array"], fmap
    "neg": takes ["Number"], neg
    "abs": takes ["Number"], abs
    "foldr": takes ["Function", "Array"], foldr
    "fold": takes ["Function", "Array"], foldl
    "repeat": takes ["Number", null], repeat
    "pack": pack
    "unpack": takes ["Array"], unpack
}