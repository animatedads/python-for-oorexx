/*
 * dynamic-projection-smoke.rex
 *
 * UNKNOWN name projection is rebuilt from Python's current advertised
 * members.  Adding a previously nonexistent class method after a Rexx proxy
 * has been created must therefore become naturally addressable without
 * rebuilding that proxy.  Deletion must remove it again.
 */
fixture = .Python~import('dynamic_method_fixture')
ChildClass = fixture~member('ChildDevice')
brandNew = fixture~member('brand_new_method')
childObj = ChildClass~call()

if childObj~py.hasMember('brand_new_method') then exit 1

ChildClass~py.setMember('brand_new_method', brandNew)
if \childObj~py.hasMember('brand_new_method') then exit 1

/* Natural UNKNOWN dispatch must discover the newly advertised exact name. */
boundMethod = childObj~brand_new_method
if boundMethod~call~scalar <> 'brand-new:ChildDevice' then exit 1

/* Exact access remains the authoritative escape hatch. */
if childObj~member('brand_new_method')~call~scalar <> 'brand-new:ChildDevice' then exit 1

ChildClass~py.deleteMember('brand_new_method')
if childObj~py.hasMember('brand_new_method') then exit 1

say 'dynamic-name-projection-ok'
::requires 'orxpython.cls'
