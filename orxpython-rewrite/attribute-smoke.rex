fixture=.Python~import('attribute_fixture')
box=fixture~member('Box')~call()
if \ box~py.hasMember('dynamicValue') then exit 1
box~py.setMember('dynamicValue',.Python~string('changed'))
if box~member('dynamicValue')~scalar <> 'changed' then exit 1
box~py.setMember('guarded',.Python~int(42))
if box~member('guarded')~scalar <> 42 then exit 1
box~py.deleteMember('dynamicValue')
if box~py.hasMember('dynamicValue') then exit 1
same=box
other=fixture~member('Box')~call()
if \ box~py.is(same) then exit 1
if box~py.is(other) then exit 1
say 'attribute-identity-ok'
::requires 'orxpython.cls'
