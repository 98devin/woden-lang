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
    ",": b.drop
    ":": b.swap
    ";": b.dup
    "_": b.incl_range
    "!": b.apply
    ")": b.pack
    "(": b.unpack
    "@": b.rot
    "l": b.length
    ".": b.print
    
# special characters which are not operators.
# they generally just do something special within the intepreter.
specials = [
    "{" "}" "[" "]" "`"
]

interpret = (code, flags={}) ->
    ops = ^^operators # clone so runtime modifications are OK
    stacks = [[]]
    currentstack = 0
    stackoffset = 0
    applypushes = [true]
    
    pos = 0
    mainloop: while pos < code.length
        char = code[pos]
        console.log ""
        apply = applypushes[*-1]
        stack = stacks[currentstack + stackoffset]
        
        # if it's an operator, apply it.
        if char of ops
            if apply
                b.push ops[char], stack
            else
                stack.push ops[char]
            console.log JSON.stringify stack if flags.verbose
            
        # if it's a number, put it on the stack.
        else if char in ["0" to "9"]
            if flags.multidigitnumbers
                numstr = char
                while pos < code.length and code[++pos] in ["0" to "9"]
                    numstr += code[pos]
                stack.push +numstr
                pos -- # this is to make sure the non-number char is still used.
            else
                stack.push +char
            console.log JSON.stringify stack if flags.verbose
            
        # now to handle special characters which have special meanings
        else if char in specials
            switch specials.index-of char
            case 0 /* { */
                applypushes.push false
                currentstack++
                if stacks.length - stackoffset < currentstack + 1
                    stacks.push []
            case 1 /* } */
                applypushes.pop! if applypushes.length > 1
                currentstack -= 1
                if currentstack < 0
                    while stackoffset + currentstack < 0
                        stackoffset++
                        stacks.unshift []
                stacks[currentstack + stackoffset].push b.fseq stack
                stacks[currentstack + stackoffset + 1] = []
            case 2 /* [ */
                applypushes.push true
                currentstack++
                if stacks.length - stackoffset < currentstack + 1
                    stacks.push []
            case 3 /* ] */
                applypushes.pop! if applypushes.length > 1
                currentstack -= 1
                if currentstack < 0
                    while stackoffset + currentstack < 0
                        stackoffset++
                        stacks.unshift []
                stacks[currentstack + stackoffset].push stack
                stacks[currentstack + stackoffset + 1] = []
            case 4 /* ` */  # sugar for a one-operator fseq
                if ++pos < code.length
                    if code[pos] in ["0" to "9"]
                        if flags.multidigitnumbers
                            numstr = code[pos]
                            while pos < code.length and code[++pos] in ["0" to "9"]
                                numstr += code[pos]
                            stack.push b.fseq [+numstr]
                            pos -- # this is to make sure the non-number char is still used.
                        else
                            stack.push b.fseq [+char]
                    else if code[pos] of ops
                        stack.push b.fseq [ops[char]]
                    
        
        # do some random final things
        if flags.verbose
            console.log "stack: #{currentstack}, offset: #{stackoffset}, apply: #{applypushes[*-1]}"
            console.log "all stacks:", JSON.stringify stacks
        pos++ # finally, since it isn't a for loop after all

process.stdin.resume!
process.stdin.set-encoding \utf8
process.stdin.on \data (text) ->
    if text is \quit
        process.exit!
    interpret text, {
        +verbose
        +multidigitnumbers
    }