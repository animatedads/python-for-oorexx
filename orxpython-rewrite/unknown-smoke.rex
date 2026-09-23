/*
 * unknown-smoke.rex - Natural Rexx message syntax over Python objects.
 *
 * UNKNOWN is deliberately only convenience syntax over member lookup and
 * positional invocation.  The explicit bridge operations remain authoritative.
 */
datetime = .Python~import('datetime')
dateClass = datetime~date
d = dateClass~call(.Python~int(2005), .Python~int(7), .Python~int(14))

if d~year~scalar <> 2005 then exit 1
if d~month~scalar <> 7 then exit 1
if d~day~scalar <> 14 then exit 1

datetimeClass = datetime~datetime
parsed = datetimeClass~fromisoformat(.Python~string('2011-11-04T00:05:23'))
if parsed~repr <> 'datetime.datetime(2011, 11, 4, 0, 5, 23)' then exit 1

say 'unknown-dispatch-ok'
::requires 'orxpython.cls'
