"""Python-side object registry for the ooRexx-to-Python rewrite.

The native bridge deliberately exposes opaque integer identities to ooRexx
rather than CPython ``PyObject *`` values.  This module owns the corresponding
strong Python references and implements the small set of generic operations
needed by Rexx proxies.

``REFCOUNT`` below is a bridge/proxy count.  It is not CPython's internal
reference count.  Each call to ``store_object`` represents another Rexx proxy
that owns the registered object; ``delete_object`` releases that ownership.

The generic member and call operations are intentionally ordinary Python
``getattr`` and callable invocation.  Descriptors, bound methods and class
methods therefore retain Python's own semantics rather than being reproduced
inside the C++ bridge.
"""

from logging import getLogger

REFCOUNT = 0
OBJECT = 1

registry = {}


def store_object(value):
    """Return an opaque identity and retain one Rexx-proxy reference to value."""
    identity = id(value)
    entry = registry.setdefault(identity, [0, value])
    entry[REFCOUNT] += 1
    return identity


def resolve_object(identity):
    """Return the Python object represented by an existing Rexx proxy."""
    try:
        return registry[identity][OBJECT]
    except KeyError as exc:
        raise ReferenceError(f"unknown Python object identity: {identity}") from exc


def delete_object(identity):
    """Release one Rexx-proxy reference, removing the registry entry at zero."""
    entry = registry.get(identity)
    if entry is None:
        return

    if entry[REFCOUNT] <= 1:
        del registry[identity]
    else:
        entry[REFCOUNT] -= 1


def call_function(name, argument):
    """Compatibility operation retained from Kaan's initial rewrite prototype."""
    if name.upper() != "GETLOGGER":
        raise AttributeError(f"unsupported prototype function: {name}")
    return store_object(getLogger(argument))


def import_module(name):
    """Import a Python module and return a retained proxy identity."""
    import importlib
    return store_object(importlib.import_module(name))


def get_member(identity, name):
    """Resolve an exact Python attribute using normal descriptor semantics."""
    return store_object(getattr(resolve_object(identity), name))


def projected_name_map(identity):
    """Build the Rexx-selector to exact-Python-name projection for an object.

    ooRexx UNKNOWN receives normalized selectors, while Python member names are
    case-sensitive.  Projection records the exact Python spelling before Rexx
    dispatch.  A normalized selector is omitted if more than one Python name
    maps to it; collisions must use explicit ``get_member`` access.

    This is a local bridge contract.  It deliberately has no dependency on any
    external object framework.
    """
    value = resolve_object(identity)
    projected = {}
    collisions = set()
    for python_name in dir(value):
        selector = python_name.upper()
        previous = projected.get(selector)
        if previous is None:
            projected[selector] = python_name
        elif previous != python_name:
            collisions.add(selector)
    for selector in collisions:
        projected.pop(selector, None)
    return projected


def get_member_rexx(identity, rexx_selector):
    """Resolve UNKNOWN through the explicit selector projection.

    Dynamic members absent from ``dir`` and colliding/reserved selectors remain
    reachable through exact ``get_member``.  We do not case-fold and guess.
    """
    python_name = projected_name_map(identity).get(rexx_selector.upper())
    if python_name is None:
        raise AttributeError(
            f"no unambiguous projected Python member for Rexx selector "
            f"{rexx_selector!r}; use explicit member(name) for exact access"
        )
    return get_member(identity, python_name)


def call_object(identity, positional_identities):
    """Call a represented Python callable with represented positional arguments."""
    callable_object = resolve_object(identity)
    arguments = [resolve_object(item) for item in positional_identities]
    return store_object(callable_object(*arguments))


def make_int(value):
    """Create a Python integer represented by a Rexx proxy."""
    return store_object(int(value))


def make_string(value):
    """Create a Python string represented by a Rexx proxy."""
    return store_object(str(value))


def repr_object(identity):
    """Return repr(object) as text for qualification and diagnostics."""
    return repr(resolve_object(identity))


def make_none():
    """Return a retained proxy identity for Python None."""
    return store_object(None)


def make_bool(value):
    """Create a Python bool from the bridge's explicit integer truth value."""
    return store_object(bool(value))


def type_name(identity):
    """Return the qualified Python type name for diagnostics and conversion."""
    value = resolve_object(identity)
    cls = type(value)
    return f"{cls.__module__}.{cls.__qualname__}"


def scalar_kind(identity):
    """Classify only losslessly convertible built-in scalar values.

    Subclasses are intentionally not classified as built-in scalars: proxy
    semantics are retained unless the represented object is exactly one of
    None, bool, int, float, or str.
    """
    value = resolve_object(identity)
    if value is None:
        return "none"
    if type(value) is bool:
        return "bool"
    if type(value) is int:
        return "int"
    if type(value) is float:
        return "float"
    if type(value) is str:
        return "str"
    return "object"


def scalar_text(identity):
    """Return a stable textual form for a previously classified scalar."""
    value = resolve_object(identity)
    kind = scalar_kind(identity)
    if kind == "bool":
        return "1" if value else "0"
    if kind in ("int", "float", "str"):
        return str(value)
    if kind == "none":
        return ""
    raise TypeError("represented object is not a built-in scalar")


def type_object(identity):
    """Return a retained proxy for Python's authoritative type(object)."""
    return store_object(type(resolve_object(identity)))


def exact_type_is(identity, class_identity):
    """Return whether object has exactly the represented Python class."""
    return type(resolve_object(identity)) is resolve_object(class_identity)


def is_instance(identity, class_identity):
    """Delegate Python instance/subclass/ABC semantics to isinstance()."""
    return isinstance(resolve_object(identity), resolve_object(class_identity))


def is_subclass(class_identity, superclass_identity):
    """Delegate Python class inheritance semantics to issubclass()."""
    return issubclass(
        resolve_object(class_identity),
        resolve_object(superclass_identity),
    )


def call_object_kw(identity, positional_identities, keyword_names, keyword_identities):
    """Call a represented Python callable with positional and keyword proxies.

    Keyword names are Rexx strings; values remain represented Python objects.
    Python itself performs signature binding and raises its normal exceptions.
    """
    if len(keyword_names) != len(keyword_identities):
        raise ValueError("keyword name/value count mismatch")

    callable_object = resolve_object(identity)
    arguments = [resolve_object(item) for item in positional_identities]
    keywords = {
        name: resolve_object(item)
        for name, item in zip(keyword_names, keyword_identities)
    }
    return store_object(callable_object(*arguments, **keywords))


def get_item(identity, key_identity):
    """Apply Python subscription semantics and retain the resulting object."""
    return store_object(resolve_object(identity)[resolve_object(key_identity)])


def set_item(identity, key_identity, value_identity):
    """Apply Python subscription assignment semantics."""
    resolve_object(identity)[resolve_object(key_identity)] = resolve_object(value_identity)


def object_length(identity):
    """Return Python len(object); Python decides whether length is supported."""
    return len(resolve_object(identity))


def object_truth(identity):
    """Return Python truth testing, including __bool__ and __len__ semantics."""
    return bool(resolve_object(identity))


def iter_object(identity):
    """Return a retained Python iterator using the normal iterator protocol."""
    return store_object(iter(resolve_object(identity)))


def next_object(identity):
    """Return the next retained object identity, or zero on StopIteration.

    Zero is not a Python object identity in this registry, so it is reserved as
    the native exhaustion sentinel.  A Python iterator yielding None still
    returns a normal non-zero proxy identity.
    """
    try:
        value = next(resolve_object(identity))
    except StopIteration:
        return 0
    return store_object(value)


def contains_object(identity, candidate_identity):
    """Apply Python containment semantics, including iterator fallback."""
    return resolve_object(candidate_identity) in resolve_object(identity)


def compare_objects(left_identity, operator_name, right_identity):
    """Apply Python's comparison operator semantics without type special cases."""
    left = resolve_object(left_identity)
    right = resolve_object(right_identity)
    operations = {
        "eq": lambda: left == right,
        "ne": lambda: left != right,
        "lt": lambda: left < right,
        "le": lambda: left <= right,
        "gt": lambda: left > right,
        "ge": lambda: left >= right,
    }
    try:
        operation = operations[operator_name]
    except KeyError as exc:
        raise ValueError(f"unsupported comparison operator: {operator_name}") from exc
    return bool(operation())


def set_member(identity, name, value_identity):
    """Apply Python setattr semantics using the exact supplied member name."""
    setattr(resolve_object(identity), name, resolve_object(value_identity))


def delete_member(identity, name):
    """Apply Python delattr semantics using the exact supplied member name."""
    delattr(resolve_object(identity), name)


def has_member(identity, name):
    """Ask Python whether the exact supplied attribute is currently visible."""
    return hasattr(resolve_object(identity), name)


def same_object(left_identity, right_identity):
    """Return Python object identity (`is`), distinct from rich equality."""
    return resolve_object(left_identity) is resolve_object(right_identity)
