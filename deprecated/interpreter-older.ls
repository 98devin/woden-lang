b = require "./builtins-old.js"

# the operators which the interpreter will recognize.
# multicharacter operators are disabled.
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
    "~": b.neg

# special-meaning characters which are not operators.
specials = [
    "{" "}" "[" "]" "`" "'" "\""
]

# custom encoding with 256 distinguishable printable characters
# actually it's kind of 257, newline and ¦ are equivalent.
character-encoding = [
    '''Ø∑∏Δᚶᚽᛑᛙ⁻⁺¦¬£€¢¥'''
    '''⁰¹²³⁴⁵⁶⁷⁸⁹¶§«◊»¿'''
    ''' !"#$%&'()*+,-./'''
    '''0123456789:;<=>?'''
    '''@ABCDEFGHIJKLMNO'''
    '''PQRSTUVWXYZ[\]^_'''
    '''`abcdefghijklmno'''
    '''pqrstuvwxyz{|}~¤'''
    '''ĄÁÂÀÄÅÆḂÇĆČĊĎḊĐĘ'''
    '''ÉÊÈËḞĠÍÎÌÏĹĽŁṀŃŇ'''
    '''ÑÓŐÔÒÖṖŔŘŞŚŠṠŤṪÚ'''
    '''ŰÛÙÜŮẂŴẀẄÝŶỲŸŹŽŻ'''
    '''ąáâàäåæḃçćčċďḋđę'''
    '''éêèëḟġíîìïĺľłṁńň'''
    '''ñóőôòöṗŕřşśšṡťṫú'''
    '''űûùüůẃŵẁẅýŷỳÿźžż'''
].join ""

to-ascii-char-code = (char) -> char.char-code-at 0
to-char-code       = (char) -> character-encoding.index-of char
from-char-code     = (code) -> character-encoding[code]

# slightly configured stringifier
stringify = (a) ->
    JSON.stringify a, (k, v)->
        return \F if b.type(v) is \Function
        return \S if b.type(v) is \Sequence
        return v
    .replace(/"F"/g, "ƒ")     # show functions more clearly
    .replace(/"S"/g, "[...]") # show sequences more clearly
    .replace(/,/g,   " ")     # separate with space instead of commas

interpret = (code, flags={}) ->

    ops          = ^^operators # clone so runtime modifications are OK if needed
    stacks       = [[]]
    currentstack = 0
    stackoffset  = 0
    applypushes  = [true]
    pos          = 0

    #
    # functions to help parsing; they return null on failure
    #

    # parse one number
    accept-number = ->
        char = code[pos]
        return null unless char in ["0" to "9"]
        if flags.multi-digit-numbers
            while ++pos < code.length and code[pos] in ["0" to "9"]
                char += code[pos]
            pos -- # this is to make sure the non-number char is still used
        +char

    # parse one operator
    accept-operator = ->
        char = code[pos]
        return null unless char of ops
        if flags.multi-character-operators
            while ++pos < code.length and char + code[pos] of ops
                char += code[pos]
            pos -- # this is to make sure the non-op char is still used
        ops[char]

    # parse one thing of any kind
    accept-anything = ->
        accept-operator! ? accept-number!

    #
    # functions to help interpreting
    #

    # decrease stack nesting
    nesting-decrease = ->
        applypushes.pop! if applypushes.length > 1
        currentstack --
        if currentstack < 0
            while stackoffset + currentstack < 0
                stackoffset++
                stacks.unshift []

    # increase stack nesting
    nesting-increase = (next-push-setting) ->
        applypushes.push next-push-setting
        currentstack++
        if stacks.length - stackoffset < currentstack + 1
            stacks.push []

    while pos < code.length
        char  = code[pos]
        apply = applypushes[*-1]
        stack = stacks[currentstack + stackoffset]

        # if it's an operator, apply it.
        if (op = accept-operator!) isnt null
            if apply
                b.push op, stack
            else
                stack.push op
            console.log stringify stack if flags.verbose

        # if it's a number, put it on the stack.
        else if (num = accept-number!) isnt null
            stack.push num

        # handle other characters which have special meanings
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
                    if (thing = accept-anything!) isnt null
                        stack.push b.fseq [thing]

        if flags.verbose
            console.log "stack: #{currentstack}, offset: #{stackoffset}, apply: #{applypushes[*-1]}"
            console.log "all stacks:", stringify stacks
            console.log!
        pos++ # since it isn't a for loop after all

    # finally, print the result
    console.log stringify stacks[currentstack + stackoffset] unless flags.verbose
    console.log!


# start the interpreter
process.stdin.resume!
process.stdin.set-encoding \utf8
process.stdout.write ">> "
process.stdin.on \data (text) ->
    if text is \quit
        process.exit!
    interpret text, {
        -verbose
        +multi-digit-numbers
        -multi-character-operators
    }
    process.stdout.write ">> "