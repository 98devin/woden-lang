# Woden-lang
A simple, stack-based, interpreted language implemented in [livescript](http://livescript.net/) (previously python).
It is not purposefully esoteric, but functions/operators have one-character identifiers (assigned within reason).

## 1. Stack-based?
Stack-based means that every value and function are operations or transformations performed on a "stack," which acts as a list of values for later
functions to work with. Values are "pushed" and "popped" from the stack to be used as parameters. To demonstrate this, a simple
program in pseudocode to calculate `(4 + 3) * 9` might look something like this:
```javascript
push 4
push 3
add
push 9
multiply
```
The basic steps followed in this program (along with the current state of the stack) are as follows:
* `push` the value `4` to the stack; the stack is now `[4]`
* `push` the value `3` to the stack; the stack is now `[4, 3]`
* pop two items off the stack and `add` them, then push the result; the stack is now `[7]`
* `push` the value `9` to the stack; the stack is now `[7, 9]`
* pop two items off the stack and `multiply` them, then push the result; the final stack is `[63]`
This is the expected result of the expression. Success!


## 2. Basic Syntax

Because Woden is stack-based, it is more natural for functions to be written _after_ their parameters, essentially in [reverse polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation).
This exposes the stack-based nature of the calculations and so causes less friction with the implementation.
As an example, in order to calculate the value of 2 + 3, one would write `2 3 +`. 
One interesting and useful property of writing expressions this way is the elimination of the need for parentheses to reorder operations and their precedences.
This can be demonstrated by converting from infix to postfix notation:
```javascript
INFIX                       POSTFIX
1 + 2 / 3 - 4 * 5           1 2 3 / + 4 5 * -
(1 + 2) / (3 - 4) * 5       1 2 + 3 4 - / 5 *
1 + 2 / (3 - 4 * 5)         1 2 3 4 5 * - / +
```

This soon becomes second nature to deal with, and also carries with it some other benefits,
such as function currying/partial application for free and high levels of composability.

## 3. Numbers

Integer number literals can be written as you would expect in many other languages, with the exception
that the `-` operator cannot be used in prefix form to specify a negative number. Currently the
only method of obtaining a negative number is subtracting from zero.
Floating-point support is also not present yet, but will be at some point. 
Eventually, there is planned support for numbers in higher bases for more concise literals.
It is likely that the base will be one of 120, 180, etc. as they are highly divisible and so also allow the finite
expression of some fractional numbers which are non-terminating in decimal (such as 1/3).

## 4. Lists

Lists of numbers in Woden can be created in much the same way as in some other languages,
by surrounding the values with brackets. However, they are not separated by commas (as the comma is the name of another function).
What is written `[1, 2, 3, 4]` in many languages is simply `[1 2 3 4]` in Woden. The contents of lists are evaluated before the
list is pushed to the stack, thus `[1 2 3 +]` is equivalent to `[1 5]`. If you want to have a function as an element of a list or sequence,
you should use either a function block or an unevaluated list (see extra notes). Lists can be nested to any depth.

Because Woden does not have (nor do I plan to implement) a true string or character type, these data types will be represented
as lists of numbers or single numbers respectively. To make it easier to enter this kind of list, it will be possible to surround text
with single quotes to generate a list of numbers (thus `[116 104 105 115]` could be represented as `'this'` instead). 
This also allows quick construction of lists of small numbers (or even fairly high if extended ASCII is used for this).

## 5. Functions

Each function in Woden has a specified *arity*, that is, the number of parameters it needs to operate. This means no function
in the language uses a variable number of arguments for calculation (though some may operate on the whole stack). This
property is crucial to determine whether the function will be applied or simply placed on the stack as a value, leading
to the next important point:

In Woden, functions are *first-class values*, meaning
they can themselves be inputs to other functions. This enables a functional style of programming, using higher-order
functions such as `map` or `fold` rather than explicit iteration. In order to facilitate this further, function blocks can be made
which contain unevauated sequences of items to be pushed to a stack one after the other, written between curly braces.
A block which adds 3 to a number is therefore simply written `{3 +}`. To the interpreter,
this is seen as an inseperable function of its own,  indistinguishable in that regard from basic operations like `+`,
and can be used in the same ways as an argument. This allows both composition and, in effect, currying of functions.

Many functions in Woden examine the type of their arguments to choose a suitable behavior. For example, the `*` function, which
acts as multiplication on numbers but as the `map` function when used on a list and another function. Sample usage:
```javascript
2 3 *               --> 6
[1 2 3] {3 +} *     --> [4, 5, 6]
```

Sometimes, operations will be automatically applied to each
element of a list in a convenient way. For example, `[1 2 3] 4 +` yields `[5, 6, 7]`.
If it is reasonable for a function to work this way, it is probably implemented to do so.
This removes the need to `map` a function like `{4 +}` over the list instead,
although the latter option provides more flexibility for complicated sequences of operations.

## 6. Input

Woden currently has no form of input during execution in its newest iteration, beyond a commandline repl.
Consider the version currently available a sort of desktop calculator, albeit with some other abilities.
Input of several kinds will definitely be supported in the future, likely through
a more convenient html-based interface which has close interaction with the interpreter.

## 7. Extra Notes

Because `[` and `]` (and similarly `{` and `}`) are functions of their own rather than syntactic sugar, they do not necessarily
need to be matched. The `[` and `{` functions both begin a new stack, the difference being whether its contents will be evaluated.
The `]` function compiles the stack into a list and pushes it onto the next-lowest stack,
and the `}` function does the same but pushes a function block instead. 
Combining these behaviors one can achieve an *unevaluated list* (or, probably less usefully, an *evaluated function block*).
```javascript
[1 2 3 +]     --> [1 5]
{1 2 3 +]     --> [1 2 3 <add>]
{[1 2] + +}   --> {[1 2] <add> <add>}
[[1 2] + +}   --> {[2 3]} // This is the usage of `+` as the scanr operator
```
