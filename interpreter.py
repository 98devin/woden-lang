from builtin import *
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
    "i": fetch_input, # Input is inserted in this item's position
    "$": last_input, # Replaced with the most recent previous input
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

def tokenize (datastring, prettyprint=False):
    tokens = []
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
                tokens.append(operators[token])
        # Use the '#' special character to push a number value
        elif token == "#":
            index += 1
            try:
                tokens.append(num(datastring[index]))
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
            tokens.append(num(token))
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
            tokens.append(Stack(num(char) for char in token[1:]))
        # If the token is something unknown, skip it entirely
        else:
            index += 1
    if prettyprint:
        print(", ".join(str(x) if get_type(x) != "function" else "<" + x.__name__ + ">" for x in tokens))
    return tokens

def receive_inputs (tokenstring):
    # Very basic preprocessing for inputs.
    # Will be expanded as necessary to support additional input types.
    counter = 0
    tokens = []
    global inputs
    inputs.clear()
    for token in tokenstring:
        if get_type(token) == "function":
            if token.__name__ == "fetch_input":
                i = input("input {}: ".format(counter+1))
                i = eval(i)
                t = get_type(i)
                if t == "number":
                    inputs.append(i)
                elif t == "stack":
                    inputs.append(Stack(i))
                tokens.append(counter)
                tokens.append(token)
                counter += 1
            elif token.__name__ == "last_input":
                if counter >= 0:
                    tokens.append(counter - 1)
                    tokens.append(fetch_input)
                else:
                    i = input("input {}: ".format(counter+1))
                    i = eval(i)
                    t = get_type(i)
                    if t == "number":
                        inputs.append(i)
                    elif t == "stack":
                        inputs.append(Stack(i))
                    tokens.append(counter)
                    tokens.append(token)
                    counter += 1
            else:
                tokens.append(token)
        else:
            tokens.append(token)
    return tokens

def interpret (datastring, prettyprint=False):
    tokens = tokenize(datastring, prettyprint)
    tokens = receive_inputs(tokens)
    s = StackManager()
    for token in tokens:
        s.push(token)
    s.push(out)


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
