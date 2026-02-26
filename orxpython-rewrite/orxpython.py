from logging import getLogger


registry = {}
REFCOUNT = 0
OBJECT = 1


def call_function(name, arg):
    if name == 'GETLOGGER':
        object = getLogger(arg)

    identity = store_object(object)
    return identity


def store_object(object):
    identity = id(object)

    entry = registry.setdefault(identity, [0, object])
    entry[REFCOUNT] += 1

    return identity


def delete_object(identity):
    entry = registry[identity]

    if entry[REFCOUNT] == 1:
        del registry[identity]
    else:
        entry[REFCOUNT] -= 1
