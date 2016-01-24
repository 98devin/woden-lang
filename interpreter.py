from builtin import *
import unicodedata

operators = {
    "0": 0, "1": 1, "2": 2, "3": 3, "4": 4,
    "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
    "+": add, # now is also SCAN
    "-": sub, # now is also FILTER
    "*": mul, # now is also MAP
    "/": div, # now is also FOLD
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
    "$": st_acc,
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
}


def slice (iterable, slice_length):
    return (x[:slice_length] for x in iterable)

def interpret (datastring):
    s = Stack_Manager()
    index = 0
    while index < len(datastring):
        token = ""
        token += datastring[index]
        if token in slice(operators, 1):
            slice_length = 1
            while token in slice(operators, slice_length):
                index += 1
                if index >= len(datastring):
                    break
                token += datastring[index]
                slice_length += 1
            index += 1
            while not (token in operators) and not token == "":
                token = token[0:-1]
                index -= 1
            if token == "":
                index += 1
            elif (token in operators):
                s.push(operators[token])
        elif token == "#":
            index += 1
            try: s.push(num(datastring[index]))
            except: pass
            index += 1
        elif token == "`":
            index += 1
            token = "0"
            while token[-1] != "`":
                try: token += datastring[index]
                except: break
                index += 1
            else: token = token[:-1]
            s.push(var(num(token)))
        elif token == "'":
            index += 1
            token = " "
            while token[-1] != "'":
                try: token += datastring[index]
                except: break
                index += 1
            else: token = token[:-1]
            s.push(Stack(num(char) for char in token[1:]))
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
        except:
            char = "NONE"
            name = "NO CHARACTER"
        print(str(i) + " " + char + " " + " "*(4-len(char)) + name)

if __name__ == "__main__":
    q = input(">>> ")
    while q != "quit":
        interpret(q)
        q = input(">>> ")
