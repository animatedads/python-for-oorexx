class BoundaryProbe:
    def __bool__(self):
        raise ValueError("truth exploded")
    def __contains__(self, candidate):
        raise LookupError("contains exploded")
    def __eq__(self, other):
        raise ArithmeticError("compare exploded")
    @property
    def guarded(self):
        return 1
    @guarded.setter
    def guarded(self, value):
        raise RuntimeError("setter exploded")
    @property
    def doomed(self):
        return 1
    @doomed.deleter
    def doomed(self):
        raise PermissionError("delete exploded")

class FalseProbe:
    def __bool__(self): return False
    def __contains__(self, candidate): return False
    def __eq__(self, other): return False

class ReprProbe:
    def __repr__(self):
        raise OSError("repr exploded")
