import math
import itertools
import types


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

def var (value):
    def var_ (stack_manager):
        """0"""
        stack_manager.push(value)
    return var_

def get_type (*args):
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
    # Perhaps this could be avoided, but I can't see how.

    def wrapper (stack_manager):
        args = (stack_manager.pop() for _ in range(arity(function)))
        result = function(*args)
        if result:
            if get_type(result) != "stack":
                try:
                    for item in iter(result):
                        stack_manager.push(item)
                except:
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

    def wrapper (x1, x2):
        t = get_type(x1, x2)
        if t[0] == "stack" and t[1] == "number":
            return Stack(function(item, x2) for item in x1)
        elif t[0] == "number" and t[1] == "stack":
            return Stack(function(x1, item) for item in x2)
        elif t[0] == t[1] == "stack":
            return Stack(function(b, a) for a, b in zip(x2, itertools.cycle(x1)))
        else:
            return function(x1, x2)

    w = wrapper
    w.__doc__ = function.__doc__
    w.__name__ = function.__name__
    return w


#
# Functions intended to be pushed to the stack
#


@stack_operation
@basic_recursion
def add (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] ==  t[1] == "number":
        return x2 + x1
    elif t[0] == "stack" and t[1] == "function":
        s = Stack(reversed(x1))
        s2 = Stack()
        s2.push(s[-1])
        while len(s) > 1:
            s.push(x2)
            s2.push(s[-1])
        return s2
    elif t[0] == "function" and t[1] == "stack":
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
    if t[0] == t[1] == "number":
        return x2 - x1
    elif t[0] == "stack" and t[1] == "function":
        s = Stack(x1)
        l = []
        for i in range(len(s)):
            s1 = Stack(s[i])
            s1.push(x2)
            if truthy(s1[-1]):
                l.append(s[i])
        return Stack(l)
    elif t[0] == "function" and t[1] == "stack":
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
    if t[0] ==  t[1] == "number":
        return x2 * x1
    elif t[0] == "stack" and t[1] == "function":
        s2 = Stack()
        for item in x1:
            s = Stack(item)
            s.push(x2)
            s2.push(s)
        return s2
    elif t[0] == "function" and t[1] == "stack":
        s2 = Stack()
        for item in x2:
            s = Stack(item)
            s.push(x1)
            s2.push(s)
        return s2

@stack_operation
@basic_recursion
def div (x1, x2):
    """2"""
    t = get_type(x1, x2)
    if t[0] ==  t[1] == "number":
        return x2 / x1
    elif t[0] == "stack" and t[1] == "function":
        s = Stack(reversed(x1))
        while len(s) > 1:
            s.push(x2)
        return s
    elif t[0] == "function" and t[1] == "stack":
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
        if not callable(x1):
            stack_manager.push(x1)
        else:
            stack_manager.append(x1)

def rot (stack_manager):
    """0"""
    stack_manager.rot()

def drop (stack_manager):
    """1"""
    stack_manager.drop()

def st_acc (stack_manager): # Needs to be reworked, perhaps
    """1"""
    x1 = stack_manager.stack(stack_manager.pop())
    stack_manager.push(x1)

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

def define (stack_manager):
    """2"""
    x1, x2 = stack_manager.pop(), stack_manager.pop()
    stack_manager.stack(x2).stack = [x1]

@stack_operation
def incl_range (x1, x2):
    """2"""
    if x1 > x2:
        return Stack(range(x2, x1 + 1))
    else:
        return Stack(reversed(range(x1, x2 + 1)))

@stack_operation
def get ():
    """0"""
    returnlist = []
    with open("stdin.txt") as f:
        text = str(f.read())
    lines = text.split("\n")
    for line in lines:
        contents = line.split(" ")
        if not contents: continue
        for item in contents:
            try: returnlist.append(eval(item))
            except: pass
    if not returnlist: return Stack([])
    return Stack(returnlist)

def swap (stack_manager):
    """0, 0"""
    stack_manager.swap()

@stack_operation
def arity_ (x1):
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

#
# Classes
#


class Stack (object):
    def __init__ (self, contents=(), stack_manager=None):
        try:
            self.stack = [item for item in contents]
        except TypeError:
            self.stack = [contents]
        self.evalmode = ["normal"]  # doesn't matter unless no manager
        self.stack_manager = stack_manager
        if self.stack_manager is None: self.stack_manager = self

    def clear (self):
        self.stack = []

    def push (self, item):
        if get_type(item) == "function":
            if arity(item) <= len(self.stack) and self.stack_manager.evalmode[-1] == "normal" or arity(item) == -1:
                item(self.stack_manager)
            else:
                self.append(item)
        elif get_type(item) == "stack":
            if len(item) == 1: self.push(item[0])
            else: self.append(item)
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

#    def update_arity (self):  # NO LONGER NECESSARY (but kinda cool)
#        arity0 = [arity(x)[0] if isinstance(x, types.FunctionType) else 0 for x in self.stack] + [0]
#        arity1 = [0] + [arity(x)[1] if isinstance(x, types.FunctionType) else 1 for x in self.stack]
#        total_in = 0
#        total_out = 0
#        for i in range(len(self.stack) + 1):
#            difference = arity0[i] - (arity1[i] + total_out)
#            if difference > 0:
#                total_in += difference
#            else:
#                total_out = -difference
#        self.__doc__ = "{}, {}".format(total_in, total_out)

    def __str__ (self):
        return "{" + ", ".join(str(item) if not type(item) == types.FunctionType else "<" + item.__name__ + ">" for item in self.stack) + "}"

class Stack_Manager (object):
    def __init__ (self, stacklist=None):
        self.stackpointer = (0, 0)
        self.stacklist = stacklist or {self.stackpointer:Stack((), self)}
        self.evalmode = ["normal"]

    def clear (self):
        for stack_id in self.stacklist:
            self.stacklist[stack_id].clear()

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
            self.evalmode = [("normal", True)]

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



