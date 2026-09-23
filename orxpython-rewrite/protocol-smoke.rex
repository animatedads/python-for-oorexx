/*
 * protocol-smoke.rex - Generic Python container/object protocol qualification.
 *
 * Operations delegate to Python protocols rather than recognizing list/dict
 * types in Rexx or C++.  A Python None yielded by an iterator remains a proxy;
 * Rexx .nil is reserved by py.next solely for iterator exhaustion.
 */
builtins = .Python~import('builtins')
list = builtins~member('list')~call()
list~member('append')~call(.Python~string('zero'))
list~member('append')~call(.Python~none)
list~member('append')~call(.Python~string('two'))

if list~py.length <> 3 then exit 1
if \ list~py.truth then exit 1
if list~py.getItem(.Python~int(0))~scalar <> 'zero' then exit 1

list~py.setItem(.Python~int(2), .Python~string('changed'))
if list~py.getItem(.Python~int(2))~scalar <> 'changed' then exit 1

empty = builtins~member('list')~call()
if empty~py.truth then exit 1

iterator = list~py.iter
first = iterator~py.next
second = iterator~py.next
third = iterator~py.next
finished = iterator~py.next
if first~scalar <> 'zero' then exit 1
if second == .nil then exit 1
if second~scalarKind <> 'none' then exit 1
if third~scalar <> 'changed' then exit 1
if finished \== .nil then exit 1

/* Slicing needs no bridge special case: Python's slice object is the key. */
slice = builtins~member('slice')~call(.Python~int(0), .Python~int(2))
prefix = list~py.getItem(slice)
if prefix~repr <> "['zero', None]" then exit 1

say 'object-protocol-ok'
::requires 'orxpython.cls'
