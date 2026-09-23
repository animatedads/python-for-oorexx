/*
 * keyword-smoke.rex - Explicit Python keyword argument qualification.
 */
builtins = .Python~import('builtins')
sorted = builtins~member('sorted')
list = builtins~member('list')~call()
list~member('append')~call(.Python~int(3))
list~member('append')~call(.Python~int(1))
list~member('append')~call(.Python~int(2))

result = sorted~callKw(list, .Python~kwd('reverse', .Python~bool(1)))
if result~repr <> '[3, 2, 1]' then do
    say 'FAIL keyword:' result~repr
    exit 1
end

say 'keyword-arguments-ok'
::requires 'orxpython.cls'
