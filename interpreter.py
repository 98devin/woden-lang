from builtin import *
import unicodedata
import sys
from optparse import OptionParser

operators = {
    "0": 0, "1": 1, "2": 2, "3": 3, "4": 4,
    "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
    "+": add, # now is also SCAN
    "-": sub, # now is also FILTER
    "*": mul, # now is also MAP
    "/": div, # now is also FOLD TODO: improve fold
    "%": mod,
    "^": exp,
    ">": gt,
    "<": lt,
    "=": eq,
    "&": bool_and,
    "|": bool_or,
    "~": neg,
    "[": lbrack,
    "]": rbrack,
    "{": lbrace,
    "}": rbrace,
    ";": dup,
    "@": rot,
    ",": drop,
    "?": inquire,
    "!": define,
    "_": incl_range,
    ".": out,
    "i": get_input,
    ":": swap,
    "m": max_,
    "a": join,
    "l": length, # also can test arity on a function
    "r": repeat,
    "t": transpose,
    ")": pack,
    "(": unpack,
    "S": summation,
    "P": product,
}


def slice (iterable, slice_length):
    return (x[:slice_length] for x in iterable)

def interpret (datastring):
    s = StackManager()
    index = 0
    while index < len(datastring):
        # Token set to next character
        token = datastring[index]
        # If the token is the beginning of an operator:
        if token in slice(operators, 1):
            slice_length = 1
            # Increase length of token and operator slice until they no longer match
            # This normally happens because the token is too long
            while token in slice(operators, slice_length):
                index += 1
                if index >= len(datastring):
                    break
                token += datastring[index]
                slice_length += 1
            index += 1
            # Reduce token until it matches an operator
            while not (token in operators) and not token == "":
                token = token[0:-1]
                index -= 1
            # If the token never matched, just go to the next character
            if token == "":
                index += 1
            # Otherwise, apply the operator it matched
            elif token in operators:
                s.push(operators[token])
        # Use the '#' special character to push a number value
        elif token == "#":
            index += 1
            try:
                s.push(num(datastring[index]))
            except IndexError:
                pass
            index += 1
        # Find characters between ``, push as number
        elif token == "`":
            index += 1
            token = "0"
            while token[-1] != "`":
                try:
                    token += datastring[index]
                except IndexError:
                    break
                index += 1
            else: token = token[:-1]
            s.push(var(num(token)))
        # Find characters between '', push as list of numbers
        elif token == "'":
            index += 1
            token = " "
            while token[-1] != "'":
                try:
                    token += datastring[index]
                except IndexError:
                    break
                index += 1
            else: token = token[:-1]
            s.push(Stack(num(char) for char in token[1:]))
        # If the token is something unknown, skip it entirely
        else:
            index += 1
    s.push(out)

def num (string): # will probably be expanded to base 120 or 180 later
    numdict = {
        char:value for char, value in zip("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX", range(60))
    }
    result = 0
    multiplier = 0
    for char in reversed(string):
        if char in numdict:
            result += numdict[char] * 60**multiplier
            multiplier += 1
        elif char == ".":
            result /= 60**multiplier
            multiplier = 0
    return result

def base (number, newbase): # returns a list of digits. only works well for integers.
    if newbase == 1: return [None]
    n = number
    b = newbase
    digitlist = []
    while b <= n: b *= newbase
    while n > 1e-10:
        while b > n:
            b /= newbase
            digitlist.append(0)
        n = round(n-b, 15)
        digitlist[-1] += 1
    digitlist.extend(0 for _ in range(round(math.log(b, newbase))))
    pointplace = -max(0, math.floor(math.log(number, newbase)))
    return digitlist

def printall (encoding):
    for i in range(256):
        try:
            char = bytes([i]).decode(encoding)
            name = unicodedata.name(char, "NO NAME")
        except UnicodeDecodeError:
            char = "NONE"
            name = "NO CHARACTER"
        print(str(i) + " " + char + " " + " "*(4 - len(char)) + name)

def start_repl ():
    print("Woden repl starting.")
    print("Type 'quit' to exit.")
    code = input(">>> ")
    while code != "quit":
        interpret(code)
        code = input(">>> ")

if __name__ == "__main__":
    if sys.argv[1:]:
        parser = OptionParser()
        options, args = parser.parse_args()
        parser.destroy()
        if args:
            interpret(args[0])
        else:
            start_repl()
    else:
        start_repl()
