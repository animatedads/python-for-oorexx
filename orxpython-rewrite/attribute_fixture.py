"""Fixture for generic attribute qualification."""
class Box:
    def __init__(self):
        self.dynamicValue="initial"; self._guarded=7
    @property
    def guarded(self): return self._guarded
    @guarded.setter
    def guarded(self,value): self._guarded=value
