# Key concepts of Woden

Demonstrating key concepts in Woden.
This serves as the primary documentation for the language.
Although it is divided into sections, certain parts have been placed
out of order to help comprehension when reading this document from start
to finish.

The reader is encouraged to test the examples for themselves, either
using the Woden REPL (the `-p` flag to enable persistence is recommended)
or within a file. I would be honored if you experimented
with the language and contributed bug findings, opinions, and ideas.

## How to use Woden
To use Woden, first clone this repo. Then install [node.js](https://nodejs.org/en/) (and npm)
in whichever way is recommended for your system. To setup Woden's dependencies, `cd` into the cloned directory and:
```
$ npm install livescript -g
$ npm install yargs
```
Then, to run the interpreter you have two options. Either run it directly with livescript:
```
$ lsc interpreter
```
Or, compile it to javascript and run with node:
```
$ lsc -c builtins interpreter
$ node interpreter
```

Eventually I plan to make Woden an npm package, which should make usage
and setup much simpler.

The `-h` flag will show all the command line options.
Listing no options will begin the REPL, and listing filenames
will run the interpreter on each in order, with a persistent namespace.
This means that while "importing" files is not really possible, listing them
first will make all their definitions available in later files.


# Syntax
```
(# First things first!
   This is a multiline comment #)

(# This is the multiline commenting
 # style which will be used in this document
 # when such a comment is needed.  #)


(## <- Any number of hashes can be used,
       but they must match on both ends!
       not the end: #)
       the end: ##)

(## You can (# nest things #) this way ##)

(# Or (## this ##) way #)

## This is a single-line comment.
## It ends at the next newline, like // in C, Java, etc.
## Pretty simple, really.
```



# Literals and values

## Numbers

Number literals in Woden are unsurprising if one
has experience with a C-like language, with some
exceptions. Currently all numbers must be written in base 10, but this may change.

Working examples for whole numbers include:
```
10  ## Works as expected
400_000_000  ## Underscores for clarity are fine (just not leading or trailing)
1_________0  ## 10, but with ridiculous levels of clarity
01189998819991197253  ## Leading 0's are OK too (no octal here)
```

Working examples for floating point include:
```
3.14  ## Fine
0.1009  ## Mind the 0 before the point; it's required
123.0  ## The 0 after the point is similarly necessary
999_999.999  ## Underscores work here too
1_123.129_912  ## If you want, they can be after the point as well
1____.____0  ## How not to input the number 1 (but it works)
```

Negative number literals are not possible as of yet, but
are largely superfluous when functions like `neg` (negate) exist.
Functions will be discussed later, of course.

All numbers in Woden are in fact floating-point internally, as a result
of the engine running on Javascript which has this behavior.

Finally, character literals in Woden simply represent the UTF-8 codepoint
of the character in question, which is just a number.
Character literals are made by writing `'` directly in front of the character:
```
'a  ## equivalent to 97
'か  ## equivalent to 12363
```



## Arrays

Array literals vary quite a lot from language to language,
but Woden is not altogether unusual in its syntax here.

Arrays are delineated with the `[` and `]` characters, and
the elements they contain are simply listed, separated by space.
Keep in mind that the elements are NOT separated with commas!
Arrays in Woden can be heterogenous.

Valid array literals:
```
[1 2 3]  ## Just space between, please.
[    2    ]  ## Space before or after the braces is irrelevant.
[1 2 [3 4 5]]  ## Heterogenous array example.
```

Strings in Woden are really just arrays of code points, so the
following are also technically array literals:
```
"Just an array"  ## So meta
"Real strings are for chumps"  ## Debatable
```

More about arrays later, when it'll be more relevant.



# Performing operations on values

Woden has one very pervasive design choice: it is stack-based.
This means that values are pushed onto a _stack_,
or "First-in, Last-out" (FILO) data structure when they are encountered.
Functions/operators are written AFTER the values they
modify, remove values from the stack as their parameters,
and then their results are pushed onto the stack as well.
This allows for much work to be done without
explicitly naming variables, and in fact there is no concept
of a _variable_ per se in Woden, as it is a purely functional language.

Postfix (a.k.a. RPN, [Reverse Polish Notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation)) function and operator application sounds strange,
but it isn't that hard to get used to. It also comes with some
advantages, such as not requiring parentheses to reorder operations.

Consider the following examples for a better idea of how it works.
The traditional infix is written first, followed by the equivalent in postfix:
```
1 + 2        ->  1 2 +
1 - 2        ->  1 2 -  ## Same deal
1 + 2 + 3    ->  1 2 + 3 +  ## Slightly more nefarious
1 / 2 + 3    ->  1 2 / 3 +  ## Preserves order of operations
1 / (2 + 3)  ->  1 2 3 + /  ## Still does, but no parentheses required!

## Longer examples
1 + 2 / 3 - 4 * 5      ->  1 2 3 / + 4 5 * -
(1 + 2) / (3 - 4) * 5  ->  1 2 + 3 4 - / 5 *
1 + 2 / (3 - 4 * 5)    ->  1 2 3 4 5 * - / +
```
If you come from a more lispy background, visualizing
```
1 2 3 + /
```
as
```
(1 (2 3 +) /)  ## This is valid Woden too, in fact
```
may provide some insight.

Visualizing both the operators being applied _in the order they are written_
and how each value and operator affects the stack is key.
Also important to note is that the "operator" functions are not special in
any way. Their names just happen to be made up of symbols. A summary of valid
identifiers will be explained later on.

>With that in place though, Woden just seems like a calculator.
>Besides, wouldn't it be more useful if `+` just summed up
>all the numbers I wrote before it? I demand justification!

Woden has one more important concept up its sleeve, stemming
largely from the use of stack-based mechanics, but also from
a functional design...



# Arity

The _arity_ of a function or operator is defined as the number
of arguments or parameters it takes in. A function with 2 parameters
has, of course, an arity of 2.

The mathematical operators `+`, `-`, `*`, `/` all have an arity of 2 as well,
since each requires two numbers to produce their results.

Every function in Woden has a set arity, that is, there is no ability of a function
to take a variable number of arguments as input. This enables better reasoning
about the way functions are applied, especially in a stack-based setting.
Arity in itself is a useful concept for stack-based functions, but in Woden
it also has other consequences, involving the use of functions as values,
and higher-order functions. 

If a function is referred to when there are not enough values on the stack
to perform its computation, it will be placed on the stack itself, acting as
a reference to the function and able to be used as an input to other functions.

For example, if one simply types a lone `+`
into the Woden prompt, it will result in a reference to the function being
pushed onto the stack, since there are fewer than 2 values (zero, to be precise).

On its own, arity might not seem very valuable, but it plays a large part
in function overloads, partial application, function composition, etc.



# Literals: Quite literally (a continuation)

## Functions

Function literals are kind of like lambdas in other languages.
In other words, they're anonymous functions.

They are written as a series of values between `{` and `}`,
and like arrays do not use commas as a delimiter.
Their contents are not evaluated (nor even inspected) until/unless
they are applied, whereupon their values are pushed to the stack
in the order they are written.

Valid function literals:
```
{1 2 3}  ## Like a lazily-evaluated set of numbers
{1 2 +}  ## Becomes a 3 only after being applied
{[1 2 3]}  ## Arrays within functions are perfectly acceptable
```

(However, the real use of these literals is partial application,
meaning giving a function only some of its arguments now, and the rest later,
or encapsulating a procedure for use with higher-order functions)

As an example, a function like this:
```
{2 +}
```
can represent "adding 2 to something not yet known", because
the `+` function is missing one argument, which it will get from the stack later. The
equivalent in Haskell for example would be `(+ 2)` 
(since the 2 in the Woden literal is the eventual second argument to `+`).
It can then be applied to each element of a list for example, resulting in
each value within (assuming the types are compatible with the `+` function)
being incremented by 2.

Since it is in general impossible to determine a fixed arity for such literals,
they are all assumed to have an arity of 0, and any issues regarding their "true"
arity are the responsibility of the programmer to handle, unfortunately.
However, this has proven to be a non-issue in the majority of cases.

One issue is that without function literals, functions themselves can only be put on the stack
when the stack's length is less than the function's arity. That is a strange
limitation to have, and so the same effect can be achieved (with total equivalence)
by making a function literal containing one thing.

For example, the following:
```
{+}
```
is exactly equivalent to an undecorated `+` when the stack is empty, but will also guarantee
that the `+` function is not actually applied to whatever may be on the stack otherwise.

This single-element function literal pattern is quite common because of this use case,
and so Woden includes a second syntax for specifying a one-element anonymous function.
Simply put a backtick: ` before a value/identifier of any kind, and it will be encapsulated in a function.

Examples:
```
`+  ## Equivalent to {+}
`[1 2 3]  ## Equivalent to {[1 2 3]}
``-  ## Equivalent to {{-}}
`39.95  ## Equivalent to {39.95}
`[`1 `2 `[3 4]]  ## Nesting is OK, equivalent to {[{1} {2} {[3 4]}]}
```



# Names and identifiers

>Literals are convenient, but allow for little
>reuse of values or code. How can I name things to recall their values later?

The syntax for doing this is discussed in the next section, "Named functions" (because there is
no distinction between a function with 0 arguments and a constant value), but
it is important to know the sort of name which is accepted in the first place.

Names in Woden can either be made up entirely of symbol-like characters (e.g. `+/-$&!`),
or entirely of letter-like characters and numbers (e.g. `aZ_39d`) followed by any number
of single quotes (often read as `prime` in this context). Either type of name is
acceptable, but the two types of symbols cannot be used in one identifier. Using a keyword
as a name is illegal (and impossible, the parser won't understand it). The `#` character is
also forbidden in identifiers, since it is used for commenting and type signatures.
The particulars of valid identifiers are still subject to change.


Sample valid names:
```
## "word-like" identifiers:
snake_case
camelCase
PascalCase
trailingNUMBERS1999
internal_9701_numbers
ready
primedAndReady''

## "operator-like" identifiers:
+
!=
>>=
<-
<$>
???
```
Next we will discuss using these names to reference values (and procedures).



# Named functions

Woden is (in many ways) purely functional, meaning one cannot change the value of a variable
at runtime; all are effectively constants.
Nevertheless it is possible to save a value (or sequence of values to function as a procedure)
under a name to reference it later.

This is done using 3 keywords present in Woden:
```
define
->
end
```
..in that order.

The basic syntax for declaring a value looks something like this:
```
define <name> -> <values> end
```

The whitespace is not important, so the following means the same thing but usually looks nicer:
```
define <name> ->
    <values>  ## The values can of course include other identifiers.
end
```

The amount of values can actually be 0, in which case any reference to the name supplied has no effect.
Thus, the simplest possible declaration is something of the form:
```
define <name> -> end  ## Elegant in a way, but ineffective.
```
...but it isn't very useful for doing anything.


If only one value is used, then the name serves effectively as a global constant.
This can be useful in cases such as:
```
define PI -> 3.1415926 end  ## No need to type out the value elsewhere, just use PI by name.
```

With two or more values, each value will be applied to the stack in order,
resulting in essentially the same thing as a function literal, but named.
Of notable difference between literals and named functions is when/how they are applied:
Literals can only be applied using the built-in `apply` function, whereas
named functions are automatically expanded whenever they are named (with some exceptions,
which will be relevant only once more advanced features of named functions are discussed).

In this way, one could make a function like the below:
```
define addTwo -> 2 + end
```

This function is equivalent to the literal `{2 +}` except it is always applied and can be referred
to by name. To achieve true equivalence, simply do the same as was done for `+` earlier, and
wrap the name in a literal so it isn't immediately applied:
```
{addTwo}  ## Or, equally:  `addTwo
```

Functions can be recursive simply by referring to themselves in their own definition. As of now,
there is no optimization for recursive tail calls, but this is an eventual goal.
A simple (and not recommended) recursive function could look like the below:
```
define addInfinity ->
    1 +  ## add one
    addInfinity  ## Then call itself, repeating the addition forever (in theory)
end
```



## Function arguments

A procedure can be more powerful if it has more control over values from the stack to use in computation.
Thus, Woden allows functions to take arguments and reuse them in their definitions.
The syntax for arguments is easy, just list more identifiers following the function name
but preceeding the arrow, like so:
```
define function argument_1 argument_2 ... argument_n ->
    (# Do stuff with the inputs #)
end
```

When `function` is called, `argument_1` will receive the value of the top of the stack,
`argument_2` the next item, and so on. The value which is used as an argument does not remain on the stack when it
is bound to the argument name. Just as when using the pre-defined functions (like `+`), if
there are not enough arguments on the stack, a reference to the function will be pushed instead.

After arguments have been declared in this way, they can be used by name in the function body.
Arguments can have any valid identifier as a name (even symbol-y ones) and shadow the value with
the same name at the global scope, if there is one. It should be noted that Woden currently has
dynamic scoping (as opposed to lexical scoping), but since there are no nested functions or mutable
variables this is not extremely widespread in its effects. A change in scoping rules may occur later in development, if
it appears to be worthwhile.

A function with arguments is also not prevented from accessing the stack for more data if necessary.
The main motivation for named arguments in Woden was not encapsulation or purity, but a lessening
of need to use functions dedicated solely to manipulating the position of items on the stack, and instead
linking stack items to names so they can be reordered and reused in whichever way the programmer chooses.
If preventing access to the overall stack is desired, surrounding the function body in parentheses achieves this.

However, using arguments, it is trivial in Woden to define the most common stack-changing
functions such as `dup`, `swap`, `drop`, `rot` etc.
and as such they are omitted from the builtin library,
which attempts to contain only the truly necessary primitives.
Their definitions follow:
```
## Duplicates an item
define dup a ->
    a a  ## Self-explanatory, I think
end

## Swaps the top two items on the stack
define swap a b ->
    a b  ## Doesn't look swapped at a glance, but it is, since b is pushed second, making it the top.
end

## Deletes the top item of the stack
define drop a -> 
    ## Doing nothing here simply consumes `a`
end

## Brings the 3rd element to the top of the stack
define rot a b c ->
    b a c
end
```

Also of note regarding argument is that any function literal containing a reference to an argument
forms a closure. This means that functions like...
```
define makeAdder x -> {x +} end  ## Returns a function which adds x
```
...work as expected, and the return function's behavior will vary depending on the input to the parent 
function.



# Overloading

Multiple versions of a function can be defined, which will be referred to as "overloads" from now on.
These overloads MUST differ from each other in at least one of three ways, or else the
interpreter will have no way to choose between them.

## Function overloads on arity

The most basic way of overloading a function is
making a version with a different arity (number of arguments). When calling the function, the
overload with the most arguments which can be validly called is used. Here is an example to clarify:
```
## Takes only one argument and adds 10 to it.
define overloaded a ->
    a 10 +
end

## Takes two arguments, and multiplies them.
define overloaded a b ->
    a b *
end

## Now, we can use the function `overloaded` in two ways:

## 1.
(29 overloaded)  ## Results in 39 by calling the version which only needs one argument.
## 2.
(18 32 overloaded)  (# Results in 576 by calling the version taking two arguments.
                     # Although the one-argument version is also valid here, the overload
                     # with the highest arity is always chosen if it applies.  #)

overloaded  (# Results in 22464 by calling the two-argument overload on the past two results!
             # Implicit argument-passing is one benefit of a stack-based system.  #)
```

Of course, when one function takes on multiple arities, it becomes important sometimes
to control exactly how many values are being passed to it. Surrounding a function with parentheses as shown
above evaluates it within a separate environment which does not contain the previous contents of the stack.
This allows access to the lower-arity overloads whenever it is needed.

This syntax with parentheses also allows evaluation of expressions inside arrays.
Typically, writing `[1 2 +]` is equivalent to `[1 2 {+}]`, because each element of the array is
evaluated in a separate and empty environment. However, writing `[(1 2 +)]` results in `[3]` because
the parenthetical expression is evaluated first and pushes the resulting values to the array. Similarly,
`[(1 2 + 3 4 + 5 6 +)]` is equivalent to `[3 7 11]`.



## Function overloads on types

Overloading functions based on types is a key feature of Woden (and many other languages).
It enables a basic level of type safety and polymorphism.
In order to do this, parameters must have their types explicitly specified.
Types are specified by the following symbol combinations:

* `#` for Numeric types (all numbers)
* `()` for Function types (literals & references caused by arity)
* `[]` for Array types (all arrays)

They are written following the parameter's name in the function definition, e.g.
```
... number_parameter# array_parameter[] ...
                    ^ here           ^^ and here
```
Depending on the type of the parameter at runtime,
a different version of the function will be called,
or, if no version of the function is appropriate, the
call will be rejected. If more than one overload can be
used, the call will also be rejected, since it is ambiguous.

However, if multiple overloads are possible but one has more
matching type checks than the others, it will take priority.
This is important to remember when writing your own functions
or reading this documentation as parts may be confusing if this
is forgotten. Two overloads with the same number of matching
types will still be rejected as ambiguous.

A basic type-finding function can be implemented like so:
```
## Matches values of different types and returns an appropriate descriptive string
define type a#  -> "Number"   end
define type a() -> "Function" end
define type a[] -> "Array"    end

(# Note above that the parameter a is never returned to the stack.
 # Because of this, it is consumed when `type` is called.
 # More on this will be discussed later.  #)
```


## Function overloads on values

More rarely found in a programming language is the ability
to overload a function based on values, rather than types.
In Woden, this is done by appending a function literal to the
end of the parameter, following the type if it is present, like so:
```
... parameter_name # { .... } ...
                     ^ here ^
```
If the function applied to the parameter's runtime argument
in an empty stack results in the top of the stack being truthy,
it is considered a match. (Because of this, an empty check evaluates
the truthiness of the value itself. In Woden, everything other than 0
is considered true. There is no separate boolean type.)

The following function implements the (recursive) fibonacci function
using this ability.
```
(# The first two numbers are 0 and 1, so for a < 2, fib(a) == a!
 # This is of course flawed if a is negative, but the fibonacci numbers
 # are not traditionally defined in that range either, so no big deal.  #)

define fibonacci a#{2 <} ->
    a
end


(# Recursion is as simple as it gets; no special case here!
 # The opposite value check of {1 >} need not be supplied,
 # since the overload with the most matching value checks is prioritized.  #)

define fibonacci a# ->
    (a 2 - fibonacci) (a 1 - fibonacci) +
end
```

## Unnamed parameters

Function parameters do not need to be named, in fact.
If they are unnamed, the value they refer to is left intact on the stack instead of being
consumed, but is still type- and value-checked.

A function parameter can be unnamed _only_ if one specifies a type and/or
value check for it, since otherwise its existence would not be evident. 

If the parameter does not need a name,
type checking, or value checking, it can be simply left implicit
as a result of the stack-based nature of computation in Woden (Modifying more stack values
than your function has arguments should be frowned upon however, as it derails the usefulness of arity/purity).

The exception to this is when one wants to check the type of an unnamed deeper
value on the stack, but wants an unnamed unchecked first parameter as well. This is
not an extremely common scenaraio, but since there is no syntax for an "unspecified" type as of yet,
it is necessary to either
* name the first parameter anyway, or
* use a value check of `{1}` to accept all values

in this case.
Perhaps syntax will be introduced to resolve this issue.

With unnamed parameters the following definition:
```
define add x# y# -> x y + end
```
can be transformed into this one, using unnamed parameters:
```
define add # # -> + end
```
This has the advantage of preserving type safety and arity information
while not forcing the writer to repeat themselves.

Also useful is the ability to use unnamed parameters to deliberately not consume 
values from the stack when doing so isn't necessary. The `type` function written previously could
be made to do this:
```
## Because of unnamed parameters, the types are checked but the values stay on the stack.
define type # -> "Number" end
define type () -> "Function" end
define type [] -> "Array" end
```



# Example functions demonstrating use cases

## If
With overloads of values and types, alongside function literals which act as closures, 
even the `if` control construct can be written as a function, rather than a keyword.
Implementation and usage example:
```
(# If the condition is true (an empty value check effectively
 # evaluates the truthiness of the value itself),
 # apply the function representing the true path's contents.  #)

define if truepath() condition{} ->
    truepath apply
end

## Otherwise, do nothing at all.
define if truepath() condition -> end

## Using the function:
10 (2 3 >) { 3 + } if  ## -> 10
10 (7 7 =) { 2 * } if  ## -> 20    
```

## If/Else

Along the same lines, here is
`if` and `else` as a function, rather than a keyword:
```
define if_else f() t() cond{} ->
    t apply
end

define if_else f() t() cond ->
    f apply
end

## Usage:
10 (2 3 >) { 3 + } { 3 - } if_else  ## -> 7
10 (7 7 =) { 2 * } { 7 * } if_else  ## -> 20
```

## Max
```
## A function to return the maximum of two numbers
define max a# b# ->
    (a b >) { a } { b } if_else 
end

## An overload to return the maximum element of a list
define max [] ->
    `max fold
end

99 182 max  ## -> 182
[1 292 10 932 8 99] max  ## -> 932
max  ## -> 932 
```

## Unlambda interpreter/DSL
It is easy to implement the basic semantics of [Unlambda](http://www.madore.org/~david/programs/unlambda/) within Woden, as it turns out.
Here is a simple way of doing so:
```
## Convenience declarations (especially ! for apply)
define ! -> apply end
define . -> putc  end

## "r" shortcut to print newline
define r -> { 10 . } end

## ".*" shortcut to print asterisk (just for convenience, not in the spec)
define .* -> { '* . } end

## Curried "k" combinator
define k       -> {   k_1 } end
define k_1 a   -> { a k_2 } end
define k_2 a b -> 
    a
end

## Curried "s" combinator
define s         -> {     s_1 } end
define s_1 a     -> {   a s_2 } end
define s_2 a b   -> { b a s_3 } end
define s_3 a b c ->
    c b ! c a ! !
end

## Curried "v" function
define v     -> `v_1 end
define v_1 a -> `v_1 end

## "i" function
define i -> {  } end  ## the identity function is achieved by doing nothing to its arguments

```
The `d` construct specified in Unlambda would be harder to implement however, and has been left out of this sample.
However, even with just these functions, we can execute the first example program on the Unlambda site successfully:

```
## Fibonacci sequence printer (per unlambda website, albeit in reverse order here due to postfix notation)
## This is _extremely_ slow, but does work as expected. What is to blame for the speed (the interpreter or the calculation method) is unclear...
k s k ! s ! ! k !
k k i s ! k ! s ! ! r k ! s ! k ! s ! ! s k ! s ! ! s ! ! s k ! s ! k ! s ! !
s k ! s ! ! s ! ! .* k !
i k ! i i s ! ! s ! ! s ! ! !
```

More examples will be added here over time.

# Final thoughts

Woden is meant as an experimental first try at writing an interpreter for a fairly barebones language, 
and almost certainly contains several design flaws or bad practices resulting from my own naiveté. 
Improvements to the speed of interpretation above all are likely possible, but to what degree I do not know.
Should you be interested enough to examine the code itself, or even offer suggestions regarding how
to improve this project (including desirable features not yet present), I would be grateful.
