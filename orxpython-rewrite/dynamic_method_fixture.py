"""Objects used to qualify Python runtime method mutation through the bridge."""

class Person:
    def __init__(self, name):
        self.name = name

    def greet(self):
        return "original:" + self.name


def replacement_greet(self):
    return "replacement:" + self.name


def restored_greet(self):
    return "restored:" + self.name


class Robot:
    def __init__(self, model):
        self.model = model

    def action(self):
        return "default:" + self.model


def special_action(self):
    return "special:" + self.model


class BaseDevice:
    def status(self):
        return "base-v1"


class ChildDevice(BaseDevice):
    pass


def base_status_v2(self):
    return "base-v2"


def child_status(self):
    return "child-v1"


def brand_new_method(self):
    return "brand-new:" + type(self).__name__
