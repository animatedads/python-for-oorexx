/*
 * dynamic-method-smoke.rex
 *
 * Qualifies Python's own descriptor and MethodType semantics through the
 * generic bridge.  There is deliberately no bridge-specific monkey-patching
 * operation: exact attribute mutation plus ordinary Python callables suffice.
 */
fixture = .Python~import('dynamic_method_fixture')
Person = fixture~member('Person')
replacement = fixture~member('replacement_greet')
restored = fixture~member('restored_greet')

before = Person~call(.Python~string('before'))
if before~greet~call~scalar <> 'original:before' then exit 1

/* Class assignment must affect an already-created instance. */
Person~py.setMember('greet', replacement)
if before~greet~call~scalar <> 'replacement:before' then exit 1

/* ...and instances created after the replacement. */
after = Person~call(.Python~string('after'))
if after~greet~call~scalar <> 'replacement:after' then exit 1

/* Replacing again proves descriptor binding remains Python-owned. */
Person~py.setMember('greet', restored)
if before~greet~call~scalar <> 'restored:before' then exit 1
if after~greet~call~scalar <> 'restored:after' then exit 1

/* Instance-only binding uses Python's types.MethodType, not bridge magic. */
types = .Python~import('types')
Robot = fixture~member('Robot')
specialAction = fixture~member('special_action')
r1 = Robot~call(.Python~string('X-100'))
r2 = Robot~call(.Python~string('Y-200'))

bound = types~member('MethodType')~call(specialAction, r1)
r1~py.setMember('action', bound)
if r1~action~call~scalar <> 'special:X-100' then exit 1
if r2~action~call~scalar <> 'default:Y-200' then exit 1

/* Deleting the instance override must reveal the class method again. */
r1~py.deleteMember('action')
if r1~action~call~scalar <> 'default:X-100' then exit 1

say 'dynamic-method-mutation-ok'
::requires 'orxpython.cls'
