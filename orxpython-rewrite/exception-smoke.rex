/*
 * exception-smoke.rex - Python exception to ooRexx condition qualification.
 */
signal on syntax name pythonError
intClass = .Python~import('builtins')~member('int')
bad = intClass~callKw(.Python~string('not-an-int'))
say 'FAIL: Python ValueError was not raised as a Rexx condition'
exit 1

pythonError:
description = condition('A')[1]
if description~pos('ValueError') == 0 then do
    say 'FAIL exception description:' description
    exit 1
end
say 'python-exception-condition-ok'
exit 0
::requires 'orxpython.cls'
