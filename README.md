# Woden-lang
A stack-based, interpreted programming language implemented in python.  
Not purposefully esoteric, but many functions have one-letter names (assigned within reason).

## 1. Stack-based?
Stack-based means that every value and function are operations or transformations performed on a "stack," which acts as a list of values for later
functions to work with. Values are "pushed" and "popped" from the stack to be used as parameters. To demonstrate this, a simple
program in pseudocode to calculate (4+3)*9 might look something like this:
```python
push 4
push 3
add
push 9
multiply
```
The basic steps followed in this program (along with the current state of the stack) are as follows:
* `push` the value `4` to the stack; stack is now `[4]`
* `push` the value `3` to the stack; stack is now `[4, 3]`
* pop two items off the stack and `add` them, then push the result; stack is now `[7]`
* `push` the value `9` to the stack; stack is now `[7, 9]`
* pop two items off the stack and `multiply` them, then push the result; final stack is `[63]`
This is the expected result. Success!


## 2. Basic Syntax
Because Woden is stack-based, it is more natural for functions to be written _after_ their parameters, essentially in [reverse polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation).
As an example, in order to calculate the value of 2 + 3, one would write `2 3 +`. 
One interesting and useful property of writing expressions this way is the elimination of the need for parentheses to reorder operations.
This can be demonstrated by converting from infix to postfix notation:
```python
INFIX                       POSTFIX
1 + 2 / 3 - 4 * 5           1 2 3 / + 4 5 * -
(1 + 2) / (3 - 4) * 5       1 2 + 3 4 - / 5 *
1 + 2 / (3 - 4 * 5)         1 2 3 4 5 * - / +
```

It is important to mention at this point that
whitespace has no significance in the language, and an equally functional representation of `2 3 +` would be `23+`, because
Woden will identify `23` as two separate operators (a behavior which will be touched upon later). Despite this,
for clarity some spacing will be used throughout the guide.

There is no difference between a function and an operator in Woden, and functions are first-class values, meaning
they can themselves be inputs to other functions. Woden encourages a mostly functional style of programming, using higher-order
functions such as `map` or `fold` rather than explicit iteration. In order to facilitate this, "functional stacks" (hereby referred to as "fstacks") can be created
which contain unevauated lists of functions to be applied one after the other, written between curly braces. An fstack which adds 3 to a number
is written `{3 +}`. To the interpreter, this is seen as an inseperable function of its own, indistinguishable in that regard from
basic operations like `+`, and can be used in the same ways as an argument.

Sometimes, operations will be automatically applied to each
element of a list in a convenient way. For example, `[1 2 3] 4 +` yields `[5, 6, 7]`. This removes the need to `map` a function
like `{4 +}` over the list instead, although the latter option provides more flexibility for complicated sequences of operations.
