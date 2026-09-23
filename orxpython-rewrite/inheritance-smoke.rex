/*
 * inheritance-smoke.rex - Python type and inheritance relation qualification.
 *
 * These tests deliberately ask Python to decide relationships.  The bridge
 * does not inspect __bases__ or reproduce MRO/ABC/metaclass rules in Rexx.
 * bool/int proves why exact type and isinstance must remain distinct concepts.
 */
builtins = .Python~import('builtins')
boolClass = builtins~member('bool')
intClass = builtins~member('int')
objectClass = builtins~member('object')

truth = .Python~bool(1)
number = .Python~int(1)

if \ truth~py.exactTypeIs(boolClass) then exit 1
if truth~py.exactTypeIs(intClass) then exit 1
if \ truth~py.isInstanceOf(boolClass) then exit 1
if \ truth~py.isInstanceOf(intClass) then exit 1

if \ boolClass~py.isSubclassOf(intClass) then exit 1
if intClass~py.isSubclassOf(boolClass) then exit 1
if \ intClass~py.isSubclassOf(objectClass) then exit 1

if \ number~py.exactTypeIs(intClass) then exit 1
if \ number~py.isInstanceOf(objectClass) then exit 1
if \ truth~py.type~py.exactTypeIs(builtins~member('type')) then exit 1

say 'inheritance-relations-ok'
::requires 'orxpython.cls'
