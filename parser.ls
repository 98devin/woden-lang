b = require "./builtins.js"

# the operators which the interpreter will recognize
ops =
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

# special meaning prefix operators.
# the value of each key is its arity.
prefixes =
    "`": 1
    "ᚶ": 2
    "ᚽ": 1
    "ᛑ": 1
    "ᛙ": 1

# custom encoding with 256 distinguishable printable characters.
# actually it's kind of 257, but newline and ¦ are equivalent.
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

to-char-code         = (char) -> character-encoding.index-of char
from-char-code       = (code) -> character-encoding[code]
to-char-code-ASCII   = (char) -> char.char-code-at 0
from-char-code-ASCII = (code) -> String.from-char-code code

/*
The grammar as implemented currently:

         <program> ::= <block> { "¦" <block> }

           <block> ::= { <atom> }

            <atom> ::= <number>
                     | <operator>
                     | <list>
                     | <fseq>
                     | <prefix operator>

          <number> ::= <digit>+
           <digit> ::= "0" | "1" | ... | "8" | "9"

            <list> ::= "[" { <atom> } "]"
                     | "[" { <atom> } "}"

            <fseq> ::= "{" { <atom> } "]"
                     | "{" { <atom> } "}"

        <operator> ::= "+" | "-" | ... | "i" | "~"

 <prefix operator> ::= <prefix> <atom>
          <prefix> ::= "`" | "ᚶ" | "ᚽ" | "ᛑ" | "ᛙ"
*/

# a new-and-improved parser using recursive descent.
# this allows for far better parsing of nested expressions than before.
export parse = (string, flags={}) ->

    pos     = 0
    codestr = string.replace "\n", "¦"
                    .replace //[^#character-encoding]//g, ""
                    .trim!

    # facilities for printing better verbose-mode stuff
    depth       = 0
    indentation = -> "  " * depth

    # abort parsing, if error encountered
    abort = (error-msg) ->
        console.log "Warning! Parse error: #error-msg"
        process.exit!

    # get one character (and advance)
    get-char = ->
        console.log indentation! + "Character consumed: <#{peek-char!}>" if flags.verbose
        if pos + 1 < codestr.length
            codestr[pos++]
        else
            null

    # peek one character
    peek-char = ->
        if pos + 1 < codestr.length
            codestr[pos]
        else
            null

    # advance one character
    advance-char = ->
        console.log indentation! + "Position advanced." if flags.verbose
        pos++

    # test whether the code has ended
    code-end = -> peek-char! == null

    # accept one of the given options
    accept-one-of = (...accept-options) ->
        for accept-func in accept-options
            if (result = accept-func!) isnt null
                return result
        return null

    # parse whitespace
    accept-whitespace = ->
        while peek-char! == " "
            advance-char!

    # parse one number
    accept-number = ->
        return null unless peek-char! in ["0" to "9"]
        if flags.verbose
            console.log indentation! + "Accepting Number..."
            depth++
        numstr = get-char!
        if flags.multi-digit-numbers
            while not code-end! and peek-char! in ["0" to "9"]
                numstr += get-char!
        if flags.verbose
            depth --
            console.log indentation! + "...Number accepted."
        return {
            type: \number
            value: +numstr
        }

    # parse one operator (one-character operators only for now)
    accept-operator = ->
        return null unless peek-char! of ops
        console.log indentation! + "Operator accepted." if flags.verbose
        return {
            type: \operator
            name: peek-char!
            value: ops[get-char!]
        }

    # parse one list literal
    accept-list = ->
        return null unless peek-char! == "["
        if flags.verbose
            console.log indentation! + "Accepting List..."
            depth++
        advance-char! # to pass over the [ character
        contents = []
        while not code-end! and peek-char! not in "]}"
            next = accept-atom!
            break if next is null
            contents.push next
        end-char = get-char!
        should-eval = if code-end! then true else end-char == "]"
        if flags.verbose
            depth --
            console.log indentation! + "...List accepted."
        return {
            type: \list
            evaluate: should-eval
            value: contents
        }

    # parse one function block
    accept-fseq = ->
        return null unless peek-char! == "{"
        if flags.verbose
            console.log indentation! + "Accepting Fseq..."
            depth++
        advance-char! # to pass over the { character
        contents = []
        while not code-end! and peek-char! not in "]}"
            next = accept-atom!
            break if next is null
            contents.push next
        end-char = get-char!
        should-eval = if code-end! then false else end-char == "]"
        if flags.verbose
            depth --
            console.log indentation! + "...Fseq accepted."
        return {
            type: \function
            evaluate: should-eval
            value: contents
        }

    # parse one prefix operator
    accept-prefix-operator = ->
        return null unless peek-char! of prefixes
        if flags.verbose
            console.log indentation! + "Accepting Prefix Operator..."
            depth++
        prefix-op = get-char!
        contents = []
        for til prefixes[prefix-op]
            next = accept-atom!
            if next is null
                console.log "...Prefix Operator parse failure!" if flags.verbose
                return null
            contents.push next
        if flags.verbose
            depth --
            console.log indentation! + "...Prefix Operator accepted."
        return {
            type: \prefix-operator
            value: prefix-op
            arguments: contents
        }

    # parse one token of any kind
    accept-atom = ->
        accept-whitespace!
        return accept-one-of(
            accept-number,
            accept-operator,
            accept-list,
            accept-fseq,
            accept-prefix-operator
        )

    # parse one woden program
    parse-program = ->
        blocks = [{
            type: \block
            value: []
        }]
        while not code-end!
            accept-whitespace!
            if peek-char! is "¦"
                console.log "Beginning new block." if flags.verbose
                blocks.push {
                    type: \block
                    value: []
                }
                advance-char!
            else
                next = accept-atom!
                if next is null
                    advance-char!
                    continue
                console.log "Atom parsed: #{JSON.stringify next}" if flags.verbose
                blocks[*-1].value.push next
        result = {
            type: \program
            value: blocks
        }
        if flags.verbose
            console.log JSON.stringify result, null, "  "
            console.log "Parsing complete!"
            console.log!
        return result

    return parse-program!
