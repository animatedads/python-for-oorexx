m = .Python~import('exception_boundary_fixture')
bad = m~member('BoundaryProbe')~call
falsey = m~member('FalseProbe')~call
badRepr = m~member('ReprProbe')~call
none = .Python~none

-- Legitimate Python false results must remain ordinary Rexx false values.
if falsey~py.truth then raise syntax 93.900 array('false truth result was treated as failure')
if falsey~py.contains(none) then raise syntax 93.900 array('false contains result was treated as failure')
if falsey~py.eq(none) then raise syntax 93.900 array('false comparison result was treated as failure')

call expectError bad, 'truth', none, 'ValueError: truth exploded'
call expectError bad, 'contains', none, 'LookupError: contains exploded'
call expectError bad, 'compare', none, 'ArithmeticError: compare exploded'
call expectError bad, 'set', none, 'RuntimeError: setter exploded'
call expectError bad, 'delete', none, 'PermissionError: delete exploded'
call expectError badRepr, 'repr', none, 'OSError: repr exploded'

say 'structured-exception-boundary-ok'
exit 0

expectError: procedure
    use strict arg object, operation, value, expected
    signal on syntax name caught
    select
        when operation == 'truth' then discard = object~py.truth
        when operation == 'contains' then discard = object~py.contains(value)
        when operation == 'compare' then discard = object~py.eq(value)
        when operation == 'set' then discard = object~py.setMember('guarded', value)
        when operation == 'delete' then discard = object~py.deleteMember('doomed')
        when operation == 'repr' then discard = object~repr
        otherwise raise syntax 93.900 array('unknown exception-boundary operation')
    end
    raise syntax 93.900 array('expected Python exception was not raised for' operation)
caught:
    info = condition('A')
    if info == .nil | info~items == 0 then raise syntax 93.900 array('missing Python exception detail for' operation)
    if info[1] \== expected then raise syntax 93.900 array('unexpected Python exception detail:' info[1])
    return

::requires 'orxpython.cls'
