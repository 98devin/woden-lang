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
    ".": b.id

# special meaning prefix operators.
# the value of each key is its function, number of arguments and whether its args should be evaluated.
prefixes =
    "`":
        value: b.runes.fseq
        arity: 1
        evaluate: true
    "ᚶ":
        value: b.runes.on-combinator
        arity: 2
        evaluate: true
    "ᚽ":
        value: b.runes.non-consuming-apply
        arity: 1
        evaluate: true
    "ᛑ":
        value: b.runes.non-consuming-apply-swap
        arity: 1
        evaluate: true
    "ᛙ":
        value: b.runes.reverse-apply
        arity: 1
        evaluate: true
    "?":
        value: b.runes.conditional1
        arity: 2
        evaluate: false

# custom encoding with 256 distinguishable printable characters.
# actually it's kind of 257, but newline and ¦ are equivalent.
character-encoding = [
    '''Ø∑∏Δᚶᚽᛑᛙ⁻⁺¦¬£€¢¥'''
    '''⁰¹²³⁴⁵⁶⁷⁸⁹¶§«◊»¿'''
    ''' !"#$%&'()*+,-./'''
    '''0123456789:;<=>?'''
    '''@ABCDEFGHIJKLMNO'''
    '''PQRSTUVWXYZ[\\]^_'''
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

to-char-code        = (char) -> character-encoding.index-of char
from-char-code      = (code) -> character-encoding[code]
to-char-code-UTF8   = (char) -> char.char-code-at 0
from-char-code-UTF8 = (code) -> String.from-char-code code

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
                     | "'" ([#character-encoding])
           <digit> ::= "0" | "1" | ... | "8" | "9"

            <list> ::= "[" { <atom> } "]"
                     | "[" { <atom> } "}"
                     | '"' { ([^"]) } '"'

            <fseq> ::= "{" { <atom> } "]"
                     | "{" { <atom> } "}"

        <operator> ::= "+" | "-" | ... | "i" | "~"

 <prefix operator> ::= <arity 1 prefix> <atom>
                     | <arity 2 prefix> <atom> <atom>
  <arity 1 prefix> ::= "`" | "ᚽ" | "ᛑ" | "ᛙ"
  <arity 2 prefix> ::= "ᚶ" | "?"
*/

# a new-and-improved parser using recursive descent.
# this allows for far better parsing of nested expressions than before.
export parse = (string, flags={}) ->

    pos     = 0
    codestr = string.trim!
                    .replace "\n", "¦"
                    .replace //[^#{JSON.stringify character-encoding}]//g, ""

    # facilities for printing better verbose-mode stuff
    depth       = 0
    indentation = -> "  " * depth

    # abort parsing, if error encountered
    abort = (error-msg) ->
        console.log "Warning! Parse error: #error-msg"
        process.exit!

    # test whether the code has ended
    code-end = -> pos >= codestr.length

    # get one character (and advance)
    get-char = ->
        console.log indentation! + "Character consumed: <#{peek-char!}>" if flags.verbose
        if not code-end!
            codestr[pos++]
        else
            null

    # peek one character
    peek-char = ->
        if not code-end!
            codestr[pos]
        else
            null

    # advance one character
    advance-char = ->
        if not code-end!
            console.log indentation! + "Position advanced past <#{peek-char!}>" if flags.verbose
            pos++

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
        return null unless peek-char! in "0123456789"
        if flags.verbose
            console.log indentation! + "Accepting Number..."
            depth++
        numstr = get-char!
        if flags.multi-digit-numbers
            while not code-end! and peek-char! in "0123456789"
                numstr += get-char!
        if flags.verbose
            depth --
            console.log indentation! + "...Number accepted."
        return {
            type: \number
            value: +numstr
        }

    # parse one quoted number
    accept-quoted-number = ->
        return null unless peek-char! is "'"
        advance-char! # to pass over the ' character
        next-char = get-char!
        return null if next-char is null
        return {
            type: \number
            value: to-char-code next-char
        }

    # parse one block reference
    accept-block-reference = ->
        return null unless peek-char! is "$"
        if flags.verbose
            console.log indentation! + "Accepting Block Reference..."
            depth++
        advance-char! # to pass over the $ character
        refnum = accept-number!
        return null if refnum is null
        if flags.verbose
            depth --
            console.log indentation! + "...Block Reference accepted."
        return {
            type: \block-reference
            value: refnum.value
        }

    /* The very concise but annoying to test way
    accept-block-reference = ->
        return null unless peek-char! in "⁰¹²³⁴⁵⁶⁷⁸⁹"
        if flags.verbose
            console.log indentation! + "Accepting Block Reference..."
            depth++
        refstr = get-char!
        if flags.multi-digit-references
            while not code-end! and peek-char! in "⁰¹²³⁴⁵⁶⁷⁸⁹"
                refstr += get-char!
        if flags.verbose
            depth --
            console.log indentation! + "...Block Reference accepted."
        real-value = +(refstr.split('').map(to-char-code >> (+ 32) >> from-char-code).join(''))
        return {
            type: \block-reference
            value: real-value
        }
    */

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

    # parse one quoted list literal
    accept-quoted-list = ->
        return null unless peek-char! == "\""
        if flags.verbose
            console.log indentation! + "Accepting Quoted List..."
            depth++
        advance-char! # to pass over the " character
        contents = []
        while not code-end! and peek-char! isnt "\""
            next-char = get-char!
            break if next-char is null
            contents.push {
                type: \number
                value: to-char-code next-char
            }
        advance-char! # to pass over the other " character
        if flags.verbose
            depth --
            console.log indentation! + "...Quoted List accepted."
        return {
            type: \list
            evaluate: false # no point anyway
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
        for til prefixes[prefix-op].arity
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
            name: prefix-op
            value: prefixes[prefix-op].value
            evaluate: prefixes[prefix-op].evaluate
            arguments: contents
        }

    # parse one token of any kind
    accept-atom = ->
        accept-whitespace!
        return accept-one-of(
            accept-number,
            accept-quoted-number,
            accept-block-reference,
            accept-operator,
            accept-list,
            accept-quoted-list,
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
            if peek-char! in "¦|"
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
