/*
 * name-projection-smoke.rex - exact Python spelling behind Rexx UNKNOWN.
 */
fixture = .Python~import('name_projection_fixture')~NamingFixture~call

if fixture~camelCase~scalar <> 'camel' then exit 1
if fixture~snake_case~scalar <> 'snake' then exit 1
if fixture~mixedMethod(.Python~string('method'))~scalar <> 'method' then exit 1

/* UNKNOWN itself is a reserved Rexx selector; exact member access is authority. */
if fixture~member('unknown')~scalar <> 'reserved' then exit 1

say 'name-projection-ok'
::requires 'orxpython.cls'
