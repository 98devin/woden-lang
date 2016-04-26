import math
import itertools
import types
import unicodedata


#
# Globally useful functions
#


def arity (function):
    return eval(function.__doc__)

def cycle (lst, amount=1):
    if lst:
        return lst[amount % len(lst):] + lst[:amount % len(lst)]
    else:
        return lst

def rotate (lst, depth, amount=1):
    if depth >= len(lst):
        return cycle(lst, amount)
    else:
        return lst[:-depth] + cycle(lst[-depth:], amount)

def truthy (x1):
    if get_type(x1) == "function":
        return True
    if get_type(x1) == "number":
        return True if x1 > 0 else False
    if get_type(x1) == "stack":
        return True if len(x1) > 0 else False
    if get_type(x1) == "boolean":
        return x1
    return False

def get_type (*args):
    # Returns a simplified type signature for an input.
    typelist = []
    typedict = {
        int: "number",
        float: "number",
        bool: "boolean",
        list: "stack",
        Stack: "stack",
        FStack: "function",
        types.FunctionType: "function",
        type(None): "none",
    }
    for arg in args:
        typelist.append(typedict[type(arg)])
    return typelist if len(typelist) > 1 else typelist[0]

def stack_operation (function):
    # A decorator which takes care of stack work.
    # The main drawback is that it wraps recursive calls too.
    # This necessitates the basic_recursion decorator.
    # Perhaps this could be avoided, but I can't see how.
    def wrapper (stack_manager):
        args = (stack_manager.pop() for _ in range(arity(function)))
        result = function(*args)
        if result is not None:
            if get_type(result) != "stack":
                try:
                    for item in iter(result):
                        stack_manager.push(item)
                except TypeError:
                    stack_manager.push(result)
            else:
                stack_manager.push(result)
    w = wrapper
    w.__doc__ = function.__doc__
    w.__name__ = function.__name__
    return w

def basic_recursion (function):
    # A decorator to implement auto-recursion/mapping on lists.
    # e.g. [123]3+ -> [456] and [123][123]+ -> [246]
    # hopefully not slow because the decorator itself recurses.
    # however, this should provide proper results at any depth.
    def wrapper (x1, x2):
        t = get_type(x1, x2)
        if t[0] == "stack" and t[1] == "number":
            return Stack(basic_recursion(function)(item, x2) for item in x1)
        elif t[0] == "number" and t[1] == "stack":
            return Stack(basic_recursion(function)(x1, item) for item in x2)
        elif t[0] == t[1] == "stack":
            return Stack(basic_recursion(function)(b, a) for a, b in zip(x2, itertools.cycle(x1)))
        else:
            return function(x1, x2)
    w = wrapper
    w.__doc__ = function.__doc__
    w.__name__ = function.__name__
    return w

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

def base (number, newbase): # TODO make work properly
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


#
# Global variables *gasp!*
#


inputs = []
dynamicoperators = {}


#
# Functions intended to be pushed to the stack
#


@stack_operation
@basic_recursion
def add (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] ==  t[1] == "number": # Add
        return x2 + x1
    elif t[0] == "stack" and t[1] == "function": # Scanl
        s = Stack(reversed(x1))
        s2 = Stack()
        s2.push(s[-1])
        while len(s) > 1:
            s.push(x2)
            s2.push(s[-1])
        return s2
    elif t[0] == "function" and t[1] == "stack": # Scanr
        s = Stack(x2)
        s2 = Stack()
        s2.push(s[-1])
        while len(s) > 1:
            s.push(x1)
            s2.push(s[-1])
        return s2

@stack_operation
@basic_recursion
def sub (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] == t[1] == "number": # Subtract
        return x2 - x1
    elif t[0] == "stack" and t[1] == "function": # Filter
        s = Stack(x1)
        l = []
        for i in range(len(s)):
            s1 = Stack(s[i])
            s1.push(x2)
            if truthy(s1[-1]):
                l.append(s[i])
        return Stack(l)
    elif t[0] == "function" and t[1] == "stack": # Filter
        s = Stack(x2)
        l = []
        for i in range(len(s)):
            s1 = Stack(s[i])
            s1.push(x1)
            if truthy(s1[-1]):
                l.append(s[i])
        return Stack(l)

@stack_operation
@basic_recursion
def mul (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] ==  t[1] == "number": # Multiply
        return x2 * x1
    elif t[0] == "stack" and t[1] == "function": # Map
        s2 = Stack()
        for item in x1:
            s = Stack([item])
            s.push(x2)
            s2.push(s)
        return s2
    elif t[0] == "function" and t[1] == "stack": # Map
        s2 = Stack()
        for item in x2:
            s = Stack([item])
            s.push(x1)
            s2.push(s)
        return s2

@stack_operation
@basic_recursion
def div (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] ==  t[1] == "number": # Divide
        return x2 / x1
    elif t[0] == "stack" and t[1] == "function": # Foldl
        s = Stack(reversed(x1))
        while len(s) > 1:
            s.push(x2)
        return s
    elif t[0] == "function" and t[1] == "stack": # Foldr
        s = Stack(x2)
        while len(s) > 1:
            s.push(x1)
        return s

@stack_operation
@basic_recursion
def mod (x1, x2):
    """2"""
    return x2 % x1

@stack_operation
@basic_recursion
def exp (x1, x2):
    """2"""
    return x2 ** x1

@stack_operation
@basic_recursion
def gt (x1, x2):
    """2"""
    return x2 > x1

@stack_operation
@basic_recursion
def lt (x1, x2):
    """2"""
    return x2 < x1

@stack_operation
def eq (x1, x2):
    """2"""
    return x2 == x1

@stack_operation
def neg (x1):
    """1"""
    t = get_type(x1)
    if t == "boolean":
        return not x1
    elif t == "stack":
        return Stack(reversed(x1))
    else:
        return -x1

@stack_operation
@basic_recursion
def bool_and (x1, x2):
    """2"""
    return truthy(x2) and truthy(x1)

@stack_operation
@basic_recursion
def bool_or (x1, x2):
    """2"""
    return truthy(x2) or truthy(x1)

def lbrace (stack_manager):
    """-1"""
    stack_manager.change_pointer(1)
    stack_manager.evalmode_change("append")

def lbrack (stack_manager):
    """-1"""
    stack_manager.change_pointer(1)
    stack_manager.evalmode_change("normal")

def rbrace (stack_manager):
    """-1"""
    stack_manager.evalmode_pop()
    x1 = FStack(stack_manager.stack())
    stack_manager.stack().clear()
    stack_manager.change_pointer(-1)
    stack_manager.append(x1)

def rbrack (stack_manager):
    """-1"""
    stack_manager.evalmode_pop()
    x1 = Stack(stack_manager.stack())
    stack_manager.stack().clear()
    stack_manager.change_pointer(-1)
    stack_manager.push(x1)

def dup (stack_manager):
    """1"""
    x1 = stack_manager.pop()
    for _ in range(2):
        stack_manager.append(x1)

def rot (stack_manager):
    """0"""
    stack_manager.rot()

def drop (stack_manager):
    """1"""
    stack_manager.drop()

def index (stack_manager):
    """0"""
    stack_manager.push(stack_manager.get_pointer())

@stack_operation
def inquire (x1, x2, x3):
    """3"""
    if truthy(x3):
        return x2
    else:
        return x1

@stack_operation
def define (x1, x2):
    """2"""
    global dynamicoperators


@stack_operation
def incl_range (x1, x2):
    """2"""
    if x1 > x2:
        return Stack(range(x2, x1 + 1))
    else:
        return Stack(reversed(range(x1, x2 + 1)))

@stack_operation
def fetch_input (x1):
    """1"""
    global inputs
    return inputs[x1]

@stack_operation
def last_input ():
    """0"""
    global inputs
    return inputs[-1]

def swap (stack_manager):
    """0"""
    stack_manager.swap()

@stack_operation
def arity_ (x1): # likely to be removed, hard to see use case
    """1"""
    return arity(x1) if callable(x1) else 0

@stack_operation
def out (x1):
    """1"""
    print("<" + x1.__name__ + ">" if type(x1) == types.FunctionType else x1)
    return x1

@stack_operation
def max_ (x1):
    """1"""
    return max_2(x1)
def max_2 (x1):
    """1"""
    t = get_type(x1)
    if t == "stack":
        return max(max_2(item) for item in x1)
    else:
        return x1

@stack_operation
def join (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] == t[1] in ["number", "function"]:
        return Stack([x2, x1])
    elif t[0] == "stack" and t[1] in ["number", "function"]:
        return Stack([x2, *x1])
    elif t[0] in ["number", "function"] and t[1] == "stack":
        return Stack([*x2, x1])
    elif t[0] == t[1] == "stack":
        return Stack([*x2, *x1])

@stack_operation
def length (x1):
    """1"""
    t = get_type(x1)
    if t == "stack":
        return len(x1)

def repeat (stack_manager):
    """2"""
    x1, x2 = stack_manager.pop(), stack_manager.pop()
    for _ in range(x1):
        stack_manager.push(x2)

@stack_operation
def transpose (x1):
    """1"""
    t = get_type(x1)
    if t == "stack":
        resultstack = Stack()
        for i in range(max(map(lambda x: len(Stack(x)), x1))):
            resultstack.push([Stack(item)[i] for item in x1 if len(Stack(item)) > i])
        return resultstack
    else:
        return x1

def pack (stack_manager): # packs all current stack contents up into one stack
    """0"""
    contents = Stack(stack_manager.get_stack())
    stack_manager.get_stack().clear()
    stack_manager.push(contents)

def unpack (stack_manager): # unpacks a stack; pushes the contents
    """1"""
    x1 = stack_manager.pop()
    t = get_type(x1)
    if t == "stack":
        for item in x1:
            stack_manager.push(item)
    else:
        stack_manager.push(x1)

@stack_operation
def summation (x1): # deep sum, may be changed to work like '+/'
    """1"""
    return summation_(x1)
def summation_ (x1):
    """1"""
    t = get_type(x1)
    if t == "stack":
        return sum(summation_(item) for item in x1)
    elif t == "function":
        return arity(x1)
    else:
        return x1

@stack_operation
def product (x1): # deep product, may be changed to work like '*/'
    """1"""
    return product_(x1)
def product_ (x1):
    """1"""
    t = get_type(x1)
    if t == "stack":
        result = 1
        for item in x1:
            result *= product_(item)
        return result
    elif t == "function":
        return arity(x1)
    else:
        return x1


#
# Classes
#


class Stack:
    def __init__ (self, contents=(), stack_manager=None):
        try:
            self.stack = [item for item in contents]
        except TypeError:
            self.stack = [contents]
        self.evalmode = ["normal"]  # Doesn't matter unless there's no manager
        if stack_manager is None:
            self.stack_manager = self
        else:
            self.stack_manager = stack_manager

    def clear (self):
        self.stack = []

    def push (self, item):
        if get_type(item) == "function":
            if arity(item) <= len(self.stack) and self.stack_manager.evalmode[-1] == "normal" or arity(item) == -1:
                item(self.stack_manager)
            else:
                self.append(item)
        elif get_type(item) == "stack":
            if item:
                if len(item) == 1:
                    self.push(item[0])
                else:
                    self.append(item)
        else:
            self.append(item)

    def append (self, item):
        self.stack.append(item)

    def pop (self):
        if len(self.stack) <= 0:
            return None
        else:
            return self.stack.pop()

    def rot (self, rotation_depth=3, rotation_amount=1):
        self.stack = rotate(self.stack, rotation_depth, rotation_amount)

    def cycle (self, cycle_amount=1):
        self.stack = cycle(self.stack, cycle_amount)

    def swap (self):
        self.stack = rotate(self.stack, 2, 1)

    def drop (self):
        self.pop()

    def get_stack (self):
        return self.stack

    def __eq__(self, other):
        if get_type(other) == "stack":
            return self.stack == other.stack
        else:
            return False

    def __gt__(self, other):
        if get_type(other) == "stack":
            return self.stack > other.stack

    def __len__ (self):
        return len(self.stack)

    def __getitem__ (self, index):
        return self.stack[index]

    def __str__ (self):
        return "[" + ", ".join(str(item) if not type(item) == types.FunctionType else "<" + item.__name__ + ">" for item in self.stack) + "]"

class FStack (Stack):
    def __init__ (self, contents=(), stack_manager=None):
        super().__init__(contents, stack_manager)
        self.__doc__ = "0"

    def __call__ (self, stack_manager):
        for item in self.stack:
            if isinstance(item, FStack):
                stack_manager.append(item)
            else:
                stack_manager.push(item)

    def push (self, item):
        self.stack.append(item)

    def __str__ (self):
        return "{" + ", ".join(str(item) if not type(item) == types.FunctionType else "<" + item.__name__ + ">" for item in self.stack) + "}"

class StackManager:
    def __init__ (self, stacklist=None):
        self.stackpointer = (0, 0)
        self.stacklist = stacklist or {self.stackpointer:Stack((), self)}
        self.evalmode = ["normal"]

    def clear_manager (self):
        for stack_id in self.stacklist:
            self.stacklist[stack_id].clear()

    def clear (self):
        self.stack().clear()

    def stack (self, stack_id=None):
        if stack_id is not None:
            if stack_id in self.stacklist:
                return self.stacklist[stack_id]
            else:
                self.stacklist[stack_id] = Stack((), self)
                return self.stacklist[stack_id]
        else:
            return self.stack(self.stackpointer)

    def pop (self):
        return self.stack().pop()

    def push (self, item):
        self.stack().push(item)

    def append (self, item):
        self.stack().append(item)

    def swap (self):
        self.stack().swap()

    def evalmode_change (self, mode):
        self.evalmode.append(mode)

    def evalmode_pop (self):
        self.evalmode.pop()
        if not self.evalmode:
            self.evalmode = ["normal"]

    def rot (self, rotation_depth=3, rotation_amount=1):
        self.stack().rot(rotation_depth, rotation_amount)

    def cycle (self, cycle_amount=1):
        self.stack().cycle(cycle_amount)

    def drop (self):
        self.stack().drop()

    def get_stack (self):
        return self.stack().get_stack()

    def change_pointer (self, amount):
        self.stackpointer = (self.stackpointer[0], self.stackpointer[1] + amount)

    def __getitem__ (self, index):
        return self.stack()[index]

    def __len__ (self):
        return len(self.stack())

    def __str__ (self):
        return "(" + ", ".join(("<"+stack.__name__+">" if isinstance(stack, types.FunctionType) else str(stack)) + ":" + str(self.stacklist[stack]) for stack in self.stacklist if len(self.stacklist[stack]) > 0) + ")"



