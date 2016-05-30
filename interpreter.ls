require! "./parser.js"
require! "./builtins.js"

# slightly configured stringifier for nicer output
stringify = (a) ->
    JSON.stringify a, (k, v)->
        return \F if builtins.type(v) is \Function
        return \S if builtins.type(v) is \Sequence
        return v
    .replace(/"F"/g, "ƒ")     # show functions more clearly
    .replace(/"S"/g, "[...]") # show sequences more clearly
    .replace(/,/g,   " ")     # separate with space instead of commas


interpret = (ast, flags={}) ->

    if typeof! ast is \String
        ast = parser.parse(ast, flags)

    # evaluate a token recursively
    evaluate = (token, extra=[]) ->
        console.log "Evaluating Token: #{JSON.stringify token}" if flags.verbose
        switch token.type
        case \number \operator
            token.value
        case \list
            stack = []
            for item in token.value
                if not token.evaluate or item.type is \function
                    stack.push evaluate(item, extra)
                else
                    builtins.push evaluate(item, extra), stack
            return stack
        case \function
            stack = []
            for item in token.value
                if not token.evaluate or item.type is \function
                    stack.push evaluate(item, extra)
                else
                    builtins.push evaluate(item, extra), stack
            return builtins.fseq stack
        case \prefix-operator
            args = []
            for item in token.arguments
                args.push evaluate(item, extra)
            return builtins.runes[token.value] ...args
        case \block
            for item in token.value
                if item.type is \function
                    extra.push evaluate(item, extra)
                else
                    res = evaluate(item, extra)
                    if res.is-fseq       # this is disgusting to me, but it works. :/
                        extra.push res   # if it didn't require special treatment, it'd be better.
                    else
                        builtins.push res, extra
            return extra
        case \program
            mainblock = token.value[0]
            stack = []
            evaluate(mainblock, stack)
            console.log stringify stack
            console.log!

    evaluate(ast) # evaluate the program


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
    }
    process.stdout.write ">> "