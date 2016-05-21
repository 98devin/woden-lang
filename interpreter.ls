b = require "./builtins.js"

# the operators which the interpreter will recognize.
# multicharacter operators are now supported.
operators =
    "+": b.add
    "-": b.sub
    "*": b.mul
    "/": b.div
    "%": b.mod
    "^": b.exp
    "<": b.lt
    ">": b.gt
    "=": b.eq
    ":": b.swap
    ";": b.dup
    "_": b.incl-range
    "!": b.apply
    ")": b.pack
    "(": b.unpack
    "@": b.rot
    "l": b.length
    "r": b.repeat
    ",": b.concat
    "w": b.while-loop
    "t": b.take
    "d": b.drop
    "|": b.bit-select
    "s": b.sequence1
    "S": b.sequence2
    "e": b.elem
    "T": b.type
    "i": b.unary-range

# special-meaning characters which are not operators.
specials = [
    "{" "}" "[" "]" "`"
]

interpret = (code, flags={}) ->

    ops = ^^operators # clone so runtime modifications are OK if needed
    stacks = [[]]
    currentstack = 0
    stackoffset = 0
    applypushes = [true]
    pos = 0

    #
    # functions to help parsing; they return null on failure
    #

    # parse one number
    accept-number = ->
        char = code[pos]
        return null unless char in ["0" to "9"]
        if flags.multidigitnumbers
            while ++pos < code.length and code[pos] in ["0" to "9"]
                char += code[pos]
            pos -- # this is to make sure the non-number char is still used
        +char

    # parse one operator
    accept-operator = ->
        char = code[pos]
        return null unless char of ops
        if flags.multicharacteroperators
            while ++pos < code.length and char + code[pos] of ops
                char += code[pos]
            pos -- # this is to make sure the non-op char is still used
        ops[char]

    # decrease 'nesting'
    nesting-decrease = ->
        applypushes.pop! if applypushes.length > 1
        currentstack -= 1
        if currentstack < 0
            while stackoffset + currentstack < 0
                stackoffset++
                stacks.unshift []

    # increase 'nesting'
    nesting-increase = (next-push-setting) ->
        applypushes.push next-push-setting
        currentstack++
        if stacks.length - stackoffset < currentstack + 1
            stacks.push []

    while pos < code.length
        char = code[pos]
        apply = applypushes[*-1]
        stack = stacks[currentstack + stackoffset]

        # if it's an operator, apply it.
        if (op = accept-operator!) isnt null
            if apply
                b.push op, stack
            else
                stack.push op
            console.log JSON.stringify stack if flags.verbose

        # if it's a number, put it on the stack.
        else if (num = accept-number!) isnt null
            stack.push num

        # now to handle special characters which have special meanings
        else if char in specials
            switch char
            case "{"
                nesting-increase false
            case "}"
                nesting-decrease!
                stacks[currentstack + stackoffset].push b.fseq stack
                stacks[currentstack + stackoffset + 1] = []
            case "["
                nesting-increase true
            case "]"
                nesting-decrease!
                stacks[currentstack + stackoffset].push stack
                stacks[currentstack + stackoffset + 1] = []
            case "`" # sugar for a one-item fseq
                if ++pos < code.length
                    if (num = accept-number!) isnt null
                        stack.push b.fseq [num]
                    else if (op = accept-operator!) isnt null
                        stack.push b.fseq [op]

        if flags.verbose
            console.log "stack: #{currentstack}, offset: #{stackoffset}, apply: #{applypushes[*-1]}"
            console.log "all stacks:", JSON.stringify stacks
            console.log!
        pos++ # since it isn't a for loop after

    # finally, print the result
    console.log JSON.stringify stacks[currentstack] unless flags.verbose
    console.log!


# actually start the interpreter
process.stdin.resume!
process.stdin.set-encoding \utf8
process.stdin.on \data (text) ->
    if text is \quit
        process.exit!
    interpret text, {
        -verbose
        +multidigitnumbers
        +multicharacteroperators
    }