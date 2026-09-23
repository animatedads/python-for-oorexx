/*
 * comparison-smoke.rex - Python containment and rich comparison qualification.
 *
 * Rexx's own =, < and > operators must not be overloaded by proxy accident.
 * Explicit py.* predicates make it clear that Python owns these semantics.
 */
builtins = .Python~import('builtins')
list = builtins~member('list')~call()
one = .Python~int(1)
two = .Python~int(2)
three = .Python~int(3)
list~member('append')~call(one)
list~member('append')~call(two)

if \ list~py.contains(one) then exit 1
if list~py.contains(three) then exit 1
if \ one~py.eq(.Python~int(1)) then exit 1
if one~py.ne(.Python~int(1)) then exit 1
if \ one~py.lt(two) then exit 1
if \ one~py.le(one) then exit 1
if \ two~py.gt(one) then exit 1
if \ two~py.ge(two) then exit 1

/* Python equality can be semantic rather than identity-based. */
a = builtins~member('list')~call()
b = builtins~member('list')~call()
a~member('append')~call(.Python~string('same'))
b~member('append')~call(.Python~string('same'))
if \ a~py.eq(b) then exit 1

say 'comparison-protocol-ok'
::requires 'orxpython.cls'
