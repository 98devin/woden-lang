# Woden-lang
A stack-based, interpreted programming language implemented in python.
Not purposefully esoteric, but many functions have one-character names (assigned within reason).

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

## 3. Functions

There is no difference between a function and an operator in Woden, and functions are first-class values, meaning
they can themselves be inputs to other functions. Woden encourages a mostly functional style of programming, using higher-order
functions such as `map` or `fold` rather than explicit iteration. In order to facilitate this, "functional stacks" (hereby referred to as "fstacks") can be created which contain unevauated lists of functions to be applied one after the other, 
written between curly braces. An fstack which adds 3 to a number is simply written `{3 +}`. 
To the interpreter, this is seen as an inseperable function of its own, 
indistinguishable in that regard from basic operations like `+`, and can be used in the same ways as an argument.

Sometimes, operations will be automatically applied to each
element of a list in a convenient way. For example, `[1 2 3] 4 +` yields `[5, 6, 7]`.
If it is reasonable for a function to work this way, it is probably implemented to do so.
This removes the need to `map` a function like `{4 +}` over the list instead, although the latter option provides more flexibility for complicated sequences of operations.

## 4. Numbers

Number literals for 0-9 can be written on their own, as shown in the examples before. However, because `10` is parsed as `1 0`, numbers higher than 9 must be written in one of two ways.  
The first option uses a higher-base counting system to represent a number up to 59 with the ordering `0-9a-zA-X` by prefixing the character with `#`. This will likely change to match each character with its ASCII byte encoding.
The second option is to surround the same type of base-60 number with backticks (`) to form a multi-digit number in base 60. The period can still be used to make a decimal. With this system, the following examples hold:
```javascript
NUMBER              WODEN LITERAL
8                   8 or #8
38                  #C
198                 `3i`
321.333333...       `5l.k`
```
As the final example illustrates, some numbers which are repeating decimals in base 10 can be represented concisely in the
higher base notation.

## 5. Lists

Lists of numbers in Woden can be created in much the same way as in other more common languages,
by surrounding the values with brackets. However, they are not separated by commas (as the comma is the name of another function).
What is written `[1, 2, 3, 4]` in many languages is simply `[1 2 3 4]` in Woden. The contents of lists are evaluated before the
list is pushed to the stack, thus `[1 2 3 +]` is equivalent to `[1 5]`. If you want to have a function as an element of a list,
you should use either a functional stack or an unevaluated list.
