require! "./parser-old.js"
require! "./builtins-old.js"

# slightly configured stringifier for nicer output
stringify = (a) ->
    JSON.stringify a, (k, v)->
        return \F if builtins.type(v) is \Function
        return \S if builtins.type(v) is \Sequence
        return v
    .replace(/"F"/g, "ƒ")     # show functions more clearly
    .replace(/"S"/g, "[...]") # show sequences more clearly
    .replace(/,/g,   " ")     # separate with space instead of commas, for more homoiconicity


interpret = (ast, flags={}) ->

    if flags.verbose or flags.timer
        time = process.hrtime! # start time of interpretation

    if typeof! ast is \String
        if flags.verbose
            console.log "Input: #{ast}"
        ast = parser.parse(ast, flags)

    # evaluate a token recursively.
    # input is a token, a stack to push things to, and a copy of the abstract syntax tree.
    evaluate = (token, stack=[], ast) ->
        console.log "Evaluating Token: #{JSON.stringify token}" if flags.verbose
        switch token.type
        case \number \operator
            token.value
        case \list
            mystack = []
            for item in token.value
                if not token.evaluate or item.type is \function
                    mystack.push evaluate(item, stack, ast)
                else
                    builtins.push evaluate(item, stack, ast), mystack
            return mystack
        case \function
            mystack = []
            for item in token.value
                if not token.evaluate or item.type is \function
                    mystack.push evaluate(item, stack, ast)
                else
                    builtins.push evaluate(item, stack, ast), mystack
            return builtins.fseq mystack
        case \prefix-operator
            args = []
            if token.evaluate
                for item in token.arguments
                    args.push evaluate(item, stack, ast)
            else
                args = token.arguments
            return token.value ...args.concat(evaluate, ast)
        case \block
            for item in token.value
                if item.type is \function
                    stack.push evaluate(item, stack, ast)
                else
                    res = evaluate(item, stack, ast)
                    if res.is-fseq       # this is disgusting to me, but it works. :/
                        stack.push res   # if it didn't require special treatment, it'd be better.
                    else
                        builtins.push res, stack
            return stack
        case \block-reference
            return builtins.mega-fseq(evaluate, ast.value[token.value], ast)
        case \program
            mainblock = token.value[0]
            progstack = []
            evaluate(mainblock, progstack, ast)
            if flags.verbose or flags.timer
                [secs, usecs] = process.hrtime(time)
                console.log "Total time taken: #{secs + usecs * 1e-9} seconds"
            console.log stringify progstack
            console.log!

    evaluate(ast, [], ast) # evaluate the program
    
    
# start the interpreter
process.stdout.write ">> "
process.stdin.set-encoding \utf8
process.stdin.on \data (text) ->
    if text is \quit
        process.exit!
    interpret text, {
        verbose: '-v' in process.argv
        timer: '-t' in process.argv
        +multi-digit-numbers
        -multi-digit-references
    }
    process.stdout.write ">> "
