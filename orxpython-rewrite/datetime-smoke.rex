/*
 * datetime-smoke.rex - Generic bridge qualification using Python datetime.
 *
 * This is intentionally not a datetime-specific implementation test.  It
 * exercises import, attribute/descriptor lookup, construction, a class method,
 * and a method call solely through the generic proxy operations.
 */
datetime = .Python~import('datetime')
dateClass = datetime~member('date')
timeClass = datetime~member('time')
datetimeClass = datetime~member('datetime')

d = dateClass~call(.Python~int(2005), .Python~int(7), .Python~int(14))
t = timeClass~call(.Python~int(12), .Python~int(30))
combine = datetimeClass~member('combine')
combined = combine~call(d, t)

expected = 'datetime.datetime(2005, 7, 14, 12, 30)'
if combined~repr <> expected then do
    say 'FAIL: expected' expected
    say '      received' combined~repr
    exit 1
end

fromisoformat = datetimeClass~member('fromisoformat')
parsed = fromisoformat~call(.Python~string('2011-11-04T00:05:23'))
expectedIso = 'datetime.datetime(2011, 11, 4, 0, 5, 23)'
if parsed~repr <> expectedIso then do
    say 'FAIL: expected' expectedIso
    say '      received' parsed~repr
    exit 1
end

say 'datetime-generic-bridge-ok'
::requires 'orxpython.cls'
