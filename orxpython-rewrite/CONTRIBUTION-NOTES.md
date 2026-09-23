# Contribution notes

This package is intentionally arranged as code another maintainer can inherit.
Exploratory binaries, caches and investigation-only programs are excluded.

The Linux work establishes three contracts before expanding the rewrite:

1. ooRexx can locate and load `liborxpython.so` on Linux.
2. The native package can initialize embedded CPython and import `orxpython.py`.
3. A Python object retained by the helper registry can be represented by an
   opaque identity in a Rexx `.Python` proxy and released safely.

The repository's reported `datetime` failure is not treated as a Python bug in
this contribution.  A standalone embedded-CPython test on the qualification
host successfully exercised date/time construction, `datetime.combine`,
`fromisoformat`, `timedelta`, and `total_seconds`.  The next investigation should
therefore reproduce those operations through the bridge and isolate the first
bridge semantic that differs.


## v0.7 portability/test-harness correction

The development-tree discovery introduced for Android is now used consistently
by both build and test scripts.  The smoke test discovers the native artifact
produced by CMake and discovers `bin/rexx` from an ooRexx development build.
This removes the earlier installed-prefix assumption from the qualification
path and makes a missing build artifact an explicit test precondition rather
than a misleading `cp`/loader failure.


## v0.8 generic object semantics

The rewrite now contains a deliberately small generic object model: module
import, attribute lookup, positional invocation, integer/string construction
and representation.  Attribute lookup is implemented with Python `getattr`,
so Python itself remains authoritative for descriptors, bound methods and
class methods.

`datetime-smoke.rex` uses only those generic operations.  There is no
datetime-specific code in the bridge.  Its purpose is to reduce the historical
datetime problem to the ordinary object/member/call contracts before the old
bridge's larger API is recreated.

## v0.9 Rexx package correction

The public Rexx proxy surface is now `orxpython.cls`, matching the established
project's class-package convention.  The rewrite prototype's `.rex` suffix is
not treated as an architectural requirement.

The `.PythonObject~init` method no longer sends an `ID=` message to an
attribute declared `get`-only.  `use strict arg id` already assigns the exposed
instance variable, exactly as the established `src/orxpython.cls` does.  This
was caught by the Android native smoke test and is now covered before the
datetime qualification runs.

## v0.10 Rexx variadic-call correction

The generic `.PythonObject~call` method now materializes its complete Rexx
argument vector with `arg(1, 'Array')`.  Rexx does not implicitly package
message arguments into the first argument.  The v0.9 implementation therefore
attempted `DO ... OVER` on the first `.PythonObject`, producing Error 98.913.

The corrected boundary is intentionally explicit: Rexx positional arguments
become one Rexx Array of opaque Python identities before entering C++.  A
zero-argument call becomes an empty Array.  Non-proxy arguments fail at the
Rexx boundary rather than being misinterpreted by the native layer.

## v0.11 explicit built-in scalar conversion

Generic calls continue to return proxies.  Conversion is now an explicit
operation on a proxy and is limited to exact Python built-ins: `None`, `bool`,
`int`, `float`, and `str`.  Subclasses and all other objects remain proxies.
This avoids silently erasing Python type/identity semantics.

`None` maps to Rexx `.nil`; Python bool maps to Rexx boolean; numeric and string
built-ins map to their Rexx scalar equivalents.  The datetime regression
remains in the standard test path.

## v0.12 Python-authoritative type and inheritance relations

The generic proxy now exposes four distinct questions: `py.type`,
`py.exactTypeIs`, `py.isInstanceOf`, and `py.isSubclassOf`.  Their answers come
from Python's `type`, `isinstance`, and `issubclass`; the bridge does not walk
`__bases__` or implement an independent inheritance model.

The regression uses Python's `bool`/`int` relationship to prove exact-type and
instance-of semantics remain distinct (`bool` is a subclass of `int`, but a
bool's exact type is not int).

## v0.13 keyword arguments and exception boundary

Keyword arguments are represented explicitly by `PythonKeywordArgument`
wrappers.  Ordinary Python dict proxies therefore remain ordinary positional
objects; the bridge never guesses that a dict means `**kwargs`.

Generic keyword invocation delegates signature binding to Python.  A Python
exception raised during that invocation is converted immediately into an
ooRexx Error 93.900 condition whose additional-information field retains the Python exception
class and message.  This replaces the previous print-and-zero behavior on this
new call path and establishes the condition-translation seam for subsequent
operations.

## v0.14 natural UNKNOWN dispatch

`PythonObject~UNKNOWN` now provides natural Rexx syntax over the existing
generic operations.  A zero-argument unknown message performs Python attribute
lookup.  An unknown message with arguments performs attribute lookup followed
by positional invocation.  The implementation delegates to the same member
and call contracts; it does not introduce a second dispatch mechanism.

Keyword calls remain explicit through `callKw`, avoiding ambiguity between
ordinary positional messages and keyword wrappers.

### ooRexx message-name case boundary

Native qualification exposed an important language mismatch: ooRexx presents
ordinary UNKNOWN message names in uppercase, while Python attribute names are
case-sensitive.  Explicit `member(name)` remains exact and is the authority
when spelling matters.  UNKNOWN uses a separate resolver: exact spelling first,
then a case-folded match only when exactly one Python attribute matches.
Ambiguity fails closed rather than choosing an arbitrary Python member.

### Callable proxy syntax

A Rexx variable containing a Python callable proxy is invoked with its explicit
`~call(...)` method.  `proxy(...)` is Rexx routine/function syntax and does not
send a message to the object.  Natural UNKNOWN dispatch applies to Python
members and methods reached as Rexx messages, not to Rexx's parser-level
function-call syntax.

## v0.15 explicit name projection

UNKNOWN no longer performs a case-folded search at dispatch time.  For each
represented Python object the bridge derives a Rexx-selector -> exact Python
name projection from Python's advertised member names.  Colliding normalized
selectors are omitted, so they fail closed and remain reachable through exact
`member(name)` access.  Dynamic names absent from `dir()` likewise use explicit
member access.  The Rexx selector `UNKNOWN` is inherently reserved by the Rexx
object protocol and is tested through the explicit path.

This borrows the proven name-projection method without importing, requiring,
or inheriting from any external object framework.

## v0.16 Python object/container protocols

The proxy exposes explicit `py.getItem`, `py.setItem`, `py.length`, `py.truth`,
`py.iter`, and `py.next` operations.  Python remains authoritative: these map
to subscription, assignment, `len`, truth testing, `iter`, and `next` rather
than recognizing container classes in Rexx or C++.

Slicing is intentionally not special bridge syntax.  A normal Python `slice`
object is passed as the subscription key, which preserves Python's complete
indexing semantics.

`py.next` returns Rexx `.nil` only for iterator exhaustion.  A Python iterator
that yields Python `None` returns a normal `PythonObject` proxy for None, so the
two states remain distinguishable.

## v0.17 containment and comparison protocols

`py.contains`, `py.eq`, `py.ne`, `py.lt`, `py.le`, `py.gt`, and `py.ge`
delegate predicates to Python.  The bridge deliberately does not reinterpret
Rexx's own comparison operators for proxy objects: explicit `py.*` operations
make the language boundary visible and preserve Python's rich-comparison
dispatch, reflected operands, and container membership behavior.

The regression also proves that Python equality is not proxy identity: two
distinct Python lists with equal contents compare equal through `py.eq`.

## v0.19 dynamic method mutation and binding qualification

No bridge-specific monkey-patching API is added.  Python already owns runtime
method mutation and descriptor binding; the bridge's generic exact-name
attribute mutation is sufficient when the assigned value is a Python callable.

`dynamic-method-smoke.rex` proves:
- assigning a Python function to a class changes method lookup for an existing
  instance and for instances constructed later;
- replacing that class function again preserves Python descriptor binding;
- `types.MethodType(function, instance)` provides an instance-only bound method;
- deleting that instance attribute exposes the original class method again.

These are black-box behavioural qualifications of Python semantics through the
bridge.  C++ does not implement descriptors, method binding, or monkey patching.

## v0.20 live method resolution across inheritance

A `PythonObject` proxy is an identity handle, not a snapshot of a Python
object's methods.  `dynamic-resolution-smoke.rex` keeps one Rexx proxy alive
while Python's class hierarchy is changed underneath it.

The regression proves that the same proxy observes an inherited method,
a later replacement on the base class, a dynamically-added subclass override,
deletion of that override with fallback through Python's MRO, and finally
deletion of the base method itself.

This is important for long-lived integrations: the bridge must not cache a
bound callable or projected implementation as the meaning of a selector.
Member projection determines only the exact Python spelling; Python performs
attribute lookup afresh and remains authoritative for descriptor and MRO
semantics.

## v0.21 qualification addition

The dynamic-name projection test now adds a previously nonexistent Python
class method after the ooRexx object proxy already exists.  Natural ooRexx
UNKNOWN dispatch discovers the newly advertised Python spelling on the next
lookup, exact `member(name)` access remains available, and deleting the class
member makes it disappear again.  This specifically checks that the bridge
does not cache a stale projected member table across runtime class mutation.

## v0.23 structured exception boundary

Native protocol operations now distinguish legitimate Python false/zero results from active Python exceptions. Truth, containment, rich comparison, attribute assignment/deletion and identity-helper failures cross to ooRexx as Error 93.900 with Python exception type/message. Destructor cleanup remains non-throwing. Added structured-exception-smoke.rex and exception_boundary_fixture.py. Full Linux native gate passes.

- v0.23 routes failures from Python `repr()` and UTF-8 conversion through the same structured ooRexx exception boundary; initialization remains the sole diagnostic `PyErr_Print()` path.

## v0.24 maintainability review

No bridge semantics were intentionally changed in this round.  The native,
Python and Rexx layers were reviewed together and comments were tightened around
the contracts that are easiest to break during future maintenance: helper
ownership, identity-result conversion, interpreter lifecycle, argument
marshalling, false-vs-exception predicates, exact-name mutation, selector
projection and Python-authoritative type relations.  Compact C++ mutation
wrappers and Rexx one-line guards were also reformatted consistently.

The full native qualification suite was rerun after the review and passed.
