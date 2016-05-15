b = require "./builtins.js"

# the operators which the interpreter will recognize.
# there is currently no support for multi-character operators.
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
    ",": b.drop1
    ":": b.swap
    ";": b.dup
    "_": b.incl-range
    "!": b.apply
    ")": b.pack
    "(": b.unpack
    "@": b.rot
    "l": b.length
    "r": b.repeat
    "j": b.join
    "w": b.while-loop
    "t": b.take
    "d": b.drop
    "s": b.bit-select

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
    # functions to help parsing
    #

    # parse one number
    accept-number = ->
        char = code[pos]
        if char in ["0" to "9"]
            if flags.multidigitnumbers
                numstr = char
                while pos < code.length and code[++pos] in ["0" to "9"]
                    numstr += code[pos]
                pos -- # this is to make sure the non-number char is still used.
                +numstr
            else
                +char
        else
            null

    # parse one operator
    accept-operator = ->
        char = code[pos]
        if char of ops
            ops[char]
        else
            null

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
            switch specials.index-of char
            case 0 /* { */
                nesting-increase false
            case 1 /* } */
                nesting-decrease!
                stacks[currentstack + stackoffset].push b.fseq stack
                stacks[currentstack + stackoffset + 1] = []
            case 2 /* [ */
                nesting-increase true
            case 3 /* ] */
                nesting-decrease!
                stacks[currentstack + stackoffset].push stack
                stacks[currentstack + stackoffset + 1] = []
            case 4 /* ` */  # sugar for a one-operator fseq
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
    }