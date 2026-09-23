/*
 * scalar-smoke.rex - Built-in scalar conversion qualification.
 *
 * Conversion is explicit.  Generic Python calls still return PythonObject
 * proxies; callers opt into scalar conversion only for exact built-in scalar
 * types.  Python None maps to Rexx .nil and bool remains distinct from int.
 */
none = .Python~none
if none~scalarKind <> 'none' then exit 1
if none~scalar \== .nil then exit 1

t = .Python~bool(1)
f = .Python~bool(0)
if t~scalarKind <> 'bool' then exit 1
if t~scalar \== .true then exit 1
if f~scalar \== .false then exit 1

i = .Python~int(42)
if i~scalarKind <> 'int' then exit 1
if i~scalar <> 42 then exit 1

text = .Python~string('bridge scalar')
if text~scalarKind <> 'str' then exit 1
if text~scalar <> 'bridge scalar' then exit 1

datetime = .Python~import('datetime')
if datetime~scalarKind <> 'object' then exit 1

say 'scalar-conversion-ok'
::requires 'orxpython.cls'
