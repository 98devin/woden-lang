# Woden
A simple, stack-based, interpreted language implemented in [livescript](http://livescript.net/) (previously python).
It is not purposefully esoteric, but functions/operators have one-character identifiers (assigned within reason).

## 1. Stack-based?
Stack-based means that every value and function are operations or transformations performed on a "stack," which acts as a list of values for later
functions to work with. Values are "pushed" and "popped" from the stack to be used as parameters. To demonstrate this, a simple
program in pseudocode to calculate `(4 + 3) * 9` might look something like this:
```js
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
```js
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
Floating-point literals are also not present yet, but will be at some point.
Eventually, there is planned support for numbers in higher bases as well for more concise literals.
It is likely that the base will be one of 120, 180, etc. as they are highly divisible and so also allow the finite
expression of some fractional numbers which are non-terminating in decimal (such as 1/3).

## 4. Lists

Lists of numbers in Woden can be created in much the same way as in some other languages,
by surrounding the values with brackets. However, they are not separated by commas (as the comma is the name of another function).
What is written `[1, 2, 3, 4]` in many languages is simply `[1 2 3 4]` in Woden. The contents of lists are evaluated when the
list is pushed to the stack, thus `[1 2 3 +]` is equivalent to `[1 5]`. If you want to have a function as an element of a normal list,
you should use either a function block or an unevaluated list (see extra notes). Lists can be nested to any depth.

Because Woden does not have a true string or character type, these data types will be represented
as lists of numbers or single numbers respectively. To make it easier to enter this kind of list, it will probably be possible eventually to surround text
with double quotes to generate a list of numbers (thus `[116 104 105 115]` could be represented like `"this"` instead).
This also allows quick construction of lists of small numbers (up to 255, since each character is one byte).

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
```js
2 3 *              // 6
[1 2 3] {3 +} *    // [4, 5, 6]
```

## 6. Sequences

Sequences in Woden aim to provide a way to interact with infinite sequences of values without sacrificing
the ease of mapping, filtering, etc. which lists enable. Any operation which makes sense to perform on infinite
lists will eventually be made to work as expected on both lists and sequences where possible. With this goal in mind,
mapping and filtering are already functional (folds are impractical/impossible however).
Sample usage:
```js
{1 +} s           // create a sequence which generates each next term by adding one
{1 +} s 5 t       // [0, 1, 2, 3, 4] (take the first five values; default starting value is 0)
[1 2 3] {1 +} S   // the same sequence, starting with a predefined list instead
[0 1] {+} S       // a sequence starting with [0, 1] and generating next terms from the sum of the two previous
[0 1] {+} S 10 t  // [0, 1, 1, 2, 3, 5, 8, 13, 21, 34] (the beginning of the fibonacci numbers!)
{1 +} s {3 *} *   // all whole numbers >= 0, then multiplied by 3
```
As you can see, Sequences are already fairly powerful, and can be used to implement certain kinds of
recursive algorithms.

## 7. Input

Woden currently has no form of input during execution in its newest iteration, just a commandline repl.
Consider the version currently available a sort of desktop calculator, albeit with some cool abilities.
Input of several kinds will definitely be supported in the future, likely through
a more convenient html-based interface which has close interaction with the interpreter.

## 8. Extra Notes

The syntax for lists and function blocks actually allows for the use of "]" or "}" as the closing
character for either. Which is used impacts whether the contents will be evaluated or not. Through this
usage, one can create a list of functions for example, or (perhaps less usefully) have the contents of
a function block evaluated before being pushed to the stack.
Using `]` as the closing character prompts evaluation of the list/block,
while `}` prevents it:
```js
[1 2 3 +]     // [1 5]
[1 2 3 +}     // [1 2 3 <+>] (the function itself is in the list)
{[1 2] + /}   // {[1 2] <+> </>}
{[1 2] + /]   // {3} (this is the usage of `/` as the fold/reduce operator)
```
