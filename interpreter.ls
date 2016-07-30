# A new interpreter for Woden, which is not reliant on one-character preset names.
# It also brings new fun features like closures, variables, context-sensitive function
# overloads, and more, making it vastly more powerful than past versions.
# This is strictly incompatible with the old interpreter, of course.

# regular expressions matching different tokens
identifier = 
    type: \identifier
    regex: /^[a-zA-Z_](?:\w|_)*'*/
    # matches identifiers like the following:
        # name
        # nameWithNumber123
        # name_with_underscores
        # _with_underscores_
        # MultiCaseName
        # nameWithTrailingQuote'
        # evenTHIS__15_ok'''
    # but not:
        # 'beginningQuote
        # intermediate'quote
        # 123beginningNumbers

operator-identifier =
    type: \identifier
    regex: /^[-~!@#$%^&*+=;:<>,.?\/\\]+/
    # matches operator-like idenifiers like the following:
        # +
        # -
        # <$>
        # !=
        # >>=
        # **
    # but not:
        # <_> (no underscores in this kind of identifier)
        # +a 
        # <'-"
        # -> (since that's a keyword)

keyword = 
    type: \keyword
    regex: /^(?:define|end|->)(?=\s|$)/
    # matches any of the keywords:
        # define
        # end
        # ->
    # but not:
        # defined
        # not-keyword-define
        # end-
        # end'
        # <->
        # ->>

number = 
    type: \number
    regex: /^\d(?:[_\d]*(?:\.[_\d]*)?\d)?/
    # matches number literals like the following:
        # 1
        # 1002392
        # 400_000_000
        # 123.0
        # 100_000.921
        # 0.09
    # but not:
        # .120
        # 2319.
        # _3
        # 10.9_

string = 
    type: \string
    regex: /^"((?:\\"|[^"])*)"/
    # matches string literals like the following:
        # "wow"
        # "string"
        # "quote inside: \" "
        # ""
    # but not:
        # """
        # "he said "hello!" to me"
        # 'single-quotes'

character = 
    type: \character
    regex: /^'(.)/
    # matches character literals like the following:
        # 'a
        # 'b
        # ''
        # '\
        # '"
    # but not:
        # a'
        # 

special = 
    type: \special
    regex: /^[\{\}\(\)\[\]#`]/
    # matches characters which cannot be present in valid identifiers:
        # [ and ]
        # { and }
        # ( and )
        # # (since it is used as a type signature)
        # ` (analogous to {}, as a function constructor)

whitespace = /^\s+/
    # matches whitespace characters:
        # space
        # tab
        # newline

# the regexes ordered by precedence
# for example, "end" is a valid identifier,
# but it must be treated as a keyword instead.
# thus, `keyword` is before `identifier` in the list.
token-expressions = [
    special,
    keyword, 
    string,
    character,
    number,
    identifier,
    operator-identifier
]


# lexer and for the new syntax.
# previously, the 'parser' had no discrete lexing phase.
# hopefully adding one will prove to be a boon.
# perhaps eventually a pipeline will be made which does things lazily/concurrently
lex = (codestr) ->

    codestr = codestr.trim! # remove unnecessary whitespace
                     # remove comments of the form (# ... #), (## ... ##), etc.
                     # this uses (?=(exp))\1 to emulate (?>exp) atomic groups
                     .replace(/\((?=(#+))\1[^#\)](?:[\s\S]*?[^#])?\1\)/gm, "")
                     # remove comments of the form ## ...
                     .replace(/##.*$/gm, "")
                     
    tokens = [] # the eventual return value of the lexer

    all-matches-failed = false # flag to determine if lexing can't continue

    while !all-matches-failed and codestr.length > 0

        # if whitespace exists before/between tokens...
        if (leading-whitespace = whitespace.exec codestr)
            # slice the codestring to get rid of it
            codestr = codestr.substr(leading-whitespace[0].length)
        
        break if codestr.length is 0
        
        
        # set it to true, to be changed during the loop
        all-matches-failed = true

        for expression in token-expressions
            # test the expression and get a result at one time
            if (result = expression.regex.exec codestr)
                all-matches-failed = false
                tokens.push {
                    type: expression.type
                    value: result
                }
                # slice the codestring to advance through it
                codestr = codestr.substr(result[0].length)
                break
        
        if all-matches-failed
            process.stdout.write ("Error when tokenizing: unexpected character: " + codestr[0] + "\n")
    
    return tokens

# parser for the new syntax.
# returns an AST object meant to be interpreted.
# this parser's resultant AST is not compatible with the older parser's.
parse = (tokens, ENV={}) ->

    # helper functions to parse the code via recursive descent

    accept-one-of = (...accept-options) ->
        for accept-function in accept-options
            if (result = accept-function!) isnt null
                return result
        return null 

    accept-number = ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \number
            tokens := rest # advance past token
            return {
                type: \number
                value: +(token.value[0].replace(/_+/g, "")) # convert value after removing underscores
            }
        else
            return null
    
    accept-identifier = ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \identifier
            tokens := rest
            return {
                type: \identifier
                value: token.value[0]
            }
        else
            return null
    
    accept-keyword = (keyword) ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \keyword
            if keyword and token.value[0] != keyword # allow matching a particular keyword
                return null
            tokens := rest
            return {
                type: \keyword
                value: token.value[0]
            }
        else
            return null
    
    accept-string = ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \string
            tokens := rest
            vals = []
            for char in token.value[1]
                vals.push {
                    type: \number
                    value: char.char-code-at 0
                }
            return {
                type: \list
                value: vals
            }
        else
            return null
    
    accept-character = ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \character
            tokens := rest
            return {
                type: \number
                value: token.value[1].char-code-at 0
            }
        else
            return null
    
    accept-special = (special) ->
        [token, ...rest] = tokens
        return null if token is undefined
        if token.type is \special
            if special and special != token.value[0]
                return null
            tokens := rest
            return {
                type: \special
                value: token.value[0]
            }
        else
            return null
    
    accept-list = ->
        return null unless accept-special("[")
        vals = []
        while (next = accept-atom!)
            vals.push next
        return null unless accept-special("]")
        return {
            type: \list
            value: vals
        }
    
    accept-fseq = ->
        return null unless accept-special("{")
        vals = []
        while (next = accept-atom!)
            vals.push next
        return null unless accept-special("}")
        return {
            type: \fseq # distinct from a named function
            value: vals
        }
    
    accept-quoted-fseq = ->
        return null unless accept-special("`")
        vals = []
        if (next = accept-atom!) is null
            return null
        else
            vals.push next
        return {
            type: \fseq
            value: vals
        }
    
    accept-expression = ->
        return null unless accept-special("(")
        vals = []
        while (next = accept-atom!)
            vals.push next
        return null unless accept-special(")")
        return {
            type: \expression
            value: vals
        }

    accept-type-restriction = ->
        if accept-special("#")
            return {
                type: \type-restriction
                value: \Number
            }
        else if accept-special("(")
            return null unless accept-special(")")
            return {
                type: \type-restriction
                value: \Function
            }
        else if accept-special("[")
            return null unless accept-special("]")
            return {
                type: \type-restriction
                value: \Array
            }
        else
            return null

    accept-function = ->
        return null unless accept-keyword("define")
        return null if (name = accept-identifier!) is null

        params = []
        paramnumber = 0
        type-restrictions = 0
        value-restrictions = 0
        until accept-keyword("->")
            param = {}
            leftout = 0
            if (paramname = accept-identifier!)
                param.name = paramname.value
                param.anonymous = false
            else
                leftout++
                param.name = paramnumber
                param.anonymous = true
            if (paramtype = accept-type-restriction!)
                param.type = paramtype.value
                type-restrictions++
            else
                leftout++
            if (paramcheck = accept-fseq!)
                param.check = paramcheck
                value-restrictions++
            else
                leftout++
            
            if leftout == 3 # no valid parameters, but also no -> keyword...
                return null # can't properly parse a function

            paramnumber++
            params.push param

        arity = paramnumber

        vals = [] # list of values the function pushes when called
        until accept-keyword("end")
            if (next = accept-atom!) is null 
                return null # because it must be malformed in this case
            vals.push next
        
        return {
            type: \function
            name: name.value
            params: params
            typechecks: type-restrictions
            valuechecks: value-restrictions
            arity: arity
            value: vals
        }

    accept-atom = ->
        # check all values which have meaning on their own
        return accept-one-of(
             accept-number,
             accept-identifier,
             accept-string,
             accept-character,
             accept-list,
             accept-fseq,
             accept-quoted-fseq,
             accept-expression
        )
    
    accept-program = (ENV = {}) ->

        # ENV is the top-level namespace
        vals = [] # top-level values/invocations, etc.

        while tokens.length > 0
            if (func = accept-function!)
                if func.name of ENV
                    ENV[func.name].overloads.push func
                else
                    ENV[func.name] = {
                        type: \function
                        name: func.name
                        overloads: [func] # representing a list of overloads
                    }
            else if (next = accept-atom!)
                vals.push next
            else # the rest of input may be malformed if neither match...
                break

        return {
            type: \program
            value: vals
            environment: ENV
        }
    
    return accept-program(ENV)


# this import is basically just for the `push`, `mega-fseq`, `truthy`, and `type` functions
require! "./builtins"

# slightly configured stringifier for nicer output
stringify = (a) ->
    JSON.stringify a, (k, v)->
        return \F if builtins.type(v) is \Function
        return \S if builtins.type(v) is \Sequence
        return v
    .replace(/"F"/g, "ƒ")     # show functions more clearly
    .replace(/"S"/g, "[...]") # show sequences more clearly
    .replace(/,/g,   " ")     # separate with space instead of commas, for more homoiconicity


# interpreter for the new syntax
interpret = (AST, ENV={}, ext_stack=[]) !->

    # it has so many arguments because they might all be needed at some point
    # but it has to also pass them down to all recursive calls...
    # ENV is a list of environments, to allow shadowing parameter names within functions
    evaluate = (node, stack, AST, ENV) ->
        switch node.type
        case \number
            stack.push node.value
        case \list
            list = []
            for subnode in node.value
                mystack = [] # each gets an empty stack, preventing application
                evaluate(subnode, mystack, AST, ENV)
                list .= concat mystack
            stack.push list
        case \expression
            mystack = []
            for subnode in node.value
                evaluate(subnode, mystack, AST, ENV)
            for result in mystack
                stack.push result # do not apply results, only push them
        case \fseq
            # lazy evaluation is desirable, so a mega-fseq is used to defer interpretation
            stack.push builtins.mega-fseq(evaluate, node.value, AST, ENV)
        case \runtime-value # an environmental value created at runtime (such as a function parameter)
            stack.push node.value
        case \identifier
            found = false # whether the identifier exists at all
            for env in ENV
                if node.value of env # if the identifier is present in the environment...
                    evaluate(env[node.value], stack, AST, ENV) # evaluate it on the stack
                    found = true # and flag that it was found in the current environment
                    break # so we don't evaluate another environment's variable too
            if not found
                process.stdout.write "Error: unknown identifier: #{node.value}\n"
                return # no way to recover from this problem, really, so just do nothing
        case \native-function # a function whose definition is supplied in livescript/javascript directly
            builtins.push node.value, stack
        
        # this is by far the most complicated part, since overloads need to be resolved
        # a new environment also needs to be made
        # this also means making sure values moved to the environment if they are named
        case \function
            overloads = node.overloads
            # filter the overloads out which need too many arguments
            overloads .= filter (overload) -> overload.arity <= stack.length
            # if no overloads with low enough arity remain...
            if overloads.length is 0
                # then save it on the stack as a value for later instead
                stack.push builtins.mega-fseq(evaluate, [node], AST, ENV)
                return # end evaluation
            # filter the overloads which have non-matching type or value requirements
            overloads .= filter (overload) ->
                param-counter = 1 # used to get the right index in the stack
                for param in overload.params
                    if param.type and builtins.type(stack[*-param-counter]) != param.type
                        return false
                    if param.check
                        mystack = [stack[*-param-counter]] # the would-be parameter, in an empty stack
                        evaluate(param.check, mystack, AST, ENV)
                        builtins.push builtins.apply, mystack # apply the check function to the item
                        return false if not builtins.truthy(mystack[*-1])
                    param-counter++
                return true
            # if no overloads with matching type/value requirements remain...
            if overloads.length is 0
                # then none of the overloads are suitable. throw an error!
                process.stdout.write "Error: function #{node.name} has no suitable overload for the arguments: "
                process.stdout.write "#{stringify stack}\n"
                return # end execution
            # at this stage all overloads should be capable of being applied.
            # now they must be sorted according to the inbuilt rules (in order):
                # higher arity > lower arity
                # more type specifiers > less type specifiers
                # more value specifiers > less value specifiers

            loop # fake loop just so we can break out of it
                # filter out lower-arity overloads
                max-arity = Math.max.apply(null, overloads.map (a) -> a.arity)
                overloads .= filter (overload) ->
                    overload.arity == max-arity
                break if overloads.length is 1

                # filter out overloads with fewer typechecks
                max-typechecks = Math.max.apply(null, overloads.map (a) -> a.typechecks)
                overloads .= filter (overload) ->
                    overload.typechecks == max-typechecks
                break if overloads.length is 1

                # filter out overloads with fewer value checks
                max-valuechecks = Math.max.apply(null, overloads.map (a) -> a.valuechecks)
                overloads .= filter (overload) ->
                    overload.valuechecks == max-valuechecks
                break if overloads.length is 1

                # if more than one overload remains, it is impossible to decide between them.
                process.stdout.write "Error: function #{node.name} has more than one suitable overload for the arguments: "
                process.stdout.write "#{stringify stack}\n"
                return # end execution

            # otherwise, we know we can use the overload which is left!
            main-overload = overloads[0]
            # now we create the environment we need
            env = {}
            param-counter = 1
            for param in main-overload.params
                if not param.anonymous
                    env[param.name] = {
                        type: \runtime-value
                        value: stack.splice(stack.length - param-counter, 1)[0]
                    }
                else
                    param-counter++ # only incremented in the else,
                                    # since taking the parameters decreases the stack's length
           
            new-ENV = [env] ++ ENV # add `env` to the list of environments
            # finally, the actual code to interpret the overload itself
            for subnode in main-overload.value
                evaluate(subnode, stack, AST, new-ENV) # that's all it takes, but so much buildup :|
        
        case \program
            for subnode in node.value
                evaluate(subnode, stack, AST, [node.environment].concat ENV) # it's that simple
            process.stdout.write "#{stringify stack}\n\n"


    evaluate(AST, ext_stack, AST, [ENV]) # start the ball rolling



#
#   Functions dealing with user interaction
#

flags = require \yargs # uses yargs to parse CLI arguments
        .usage "Usage: $0 [filepaths] [options]"
        # -v for verbose
        .count \v # more than one invocation increases verbosity
        .alias \v \verbose
        .describe \v "Enable verbose mode"
        # -b for basic (reduced default imports)
        .count \b # more than one invocation means ZERO imports
        .alias \b \basic
        .describe \b "Reduce imports enabled by default"
        # -r for REPL (instead of running from a file)
        .boolean \r
        .alias \r \repl
        .describe \r "Launch REPL environment"
        # -p for persistent REPL
        .boolean \p
        .alias \p \persistent
        .describe \p "Make REPL definitions and stack persist across entries"
        # -h for help (pretty standard)
        .help \h
        .alias \h \help
        .describe \h "Show this help message"
        # -e for execute from CLI
        .string \e
        .alias \e \execute
        .nargs \e 1
        .describe \e "Executes a string of valid Woden script"
        # other stuff
        .epilog "Made by Devin Hill 2016"
        .argv # parse those suckers

fs = require \fs

export repl = ->
    # setup a persistent environment for the repl
    # this enables function definitions to remain across inputs
    env = {}
    stack = []
    unless flags.basic >= 2
        builtins.get-environment(flags.basic < 1, env)

    # setup/start the test REPL
    process.stdin.set-encoding \utf8
    process.stdout.write "Woden REPL started.\nType `\\quit` to end execution, or `\\reset` to clear environmental variables.\n" 
    process.stdout.write ">> "
    process.stdin.on \data (text) ->

        if text.trim! == '\\quit' # command to end the interpreter
            process.exit!
        
        if !flags.persistent or text.trim! == '\\reset' # command to reset environment
            env := {} # clear environmental variables
            stack := [] # clear stack
            unless flags.basic >= 2 # but reinstate builtin functionality
                builtins.get-environment(flags.basic < 1, env)
        
        text = "" if text.trim! == '\\reset'

        tokens = lex(text)
        if flags.verbose
            process.stdout.write "Lexed tokens: #{JSON.stringify tokens} \n"
        
        program = parse(tokens, env) # `env` is updated every time
        if flags.verbose
            process.stdout.write "Parsed program: #{JSON.stringify program, null, "  "} \n"
        
        interpret(program, env, stack)
        process.stdout.write ">> "


# handle logic based on CLI arguments
if flags.repl
    repl!
else if flags.execute
    env = {} # the base environment to receive imports and whatnot
    unless flags.basic >= 2
        builtins.get-environment(flags.basic < 1, env)
    interpret(parse(lex(flags.execute), env), env)
else
    filepaths = flags._
    if filepaths.length is 0
        repl!
    else
        env = {} # the base environment to receive imports and whatnot
        stack = [] # the base stack to be operated upon by all included files
        unless flags.basic >= 2
            builtins.get-environment(flags.basic < 1, env)

        for path in filepaths
            data = fs.readFileSync path, 'utf8'
            interpret(parse(lex(data), env), env, stack)

