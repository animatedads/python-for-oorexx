/*
 * dynamic-resolution-smoke.rex
 *
 * A PythonObject proxy represents object identity, not a snapshot of method
 * lookup.  Every member lookup must therefore observe Python's current class
 * dictionaries, descriptor rules and MRO.
 */
fixture = .Python~import('dynamic_method_fixture')
Base = fixture~member('BaseDevice')
ChildClass = fixture~member('ChildDevice')
baseV2 = fixture~member('base_status_v2')
childV1 = fixture~member('child_status')

childObj = ChildClass~call()

/* Initial inherited method. */
statusMethod1 = childObj~member('status')
if statusMethod1~call~scalar <> 'base-v1' then exit 1

/* Replace method on base after child and its Rexx proxy already exist. */
Base~py.setMember('status', baseV2)
statusMethod2 = childObj~member('status')
if statusMethod2~call~scalar <> 'base-v2' then exit 1

/* Add subclass override dynamically. */
ChildClass~py.setMember('status', childV1)
statusMethod3 = childObj~member('status')
if statusMethod3~call~scalar <> 'child-v1' then exit 1

/* Delete subclass override: Python MRO must expose current base method. */
ChildClass~py.deleteMember('status')
statusMethod4 = childObj~member('status')
if statusMethod4~call~scalar <> 'base-v2' then exit 1

/* Delete base method: the same proxy must stop resolving it. */
Base~py.deleteMember('status')
if childObj~py.hasMember('status') then exit 1

say 'dynamic-method-resolution-ok'
::requires 'orxpython.cls'
