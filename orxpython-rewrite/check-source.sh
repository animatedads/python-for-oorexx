#!/usr/bin/env bash
# Check Rexx proxy invariants that do not require an ooRexx runtime.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if grep -q 'self~id = id' "$root/orxpython.cls"; then
    echo "FAIL: get-only ID attribute must not be assigned through ID=." >&2
    exit 1
fi
grep -q "::attribute id get" "$root/orxpython.cls"
grep -q "::requires 'orxpython.cls'" "$root/smoke.rex"
grep -q "::requires 'orxpython.cls'" "$root/datetime-smoke.rex"
grep -q "objects = arg(1, 'Array')" "$root/orxpython.cls"
if grep -q "use arg objects" "$root/orxpython.cls"; then
    echo "FAIL: CALL arguments must be materialized with arg(1, 'Array')." >&2
    exit 1
fi
grep -q "def scalar_kind(identity)" "$root/orxpython.py"
grep -q "::method scalar" "$root/orxpython.cls"
grep -q "::requires 'orxpython.cls'" "$root/scalar-smoke.rex"
grep -q "def is_instance(identity, class_identity)" "$root/orxpython.py"
grep -q "::method py.isSubclassOf" "$root/orxpython.cls"
grep -q "::requires 'orxpython.cls'" "$root/inheritance-smoke.rex"
grep -q "::class 'PythonKeywordArgument'" "$root/orxpython.cls"
grep -q "def call_object_kw" "$root/orxpython.py"
grep -q "pythonFailureAsRexx" "$root/orxpython.cpp"
grep -q "::method unknown" "$root/orxpython.cls"
grep -q "UNKNOWN supplies the message arguments as an Array" "$root/orxpython.cls"
grep -q "::requires 'orxpython.cls'" "$root/unknown-smoke.rex"
grep -q "def projected_name_map(identity)" "$root/orxpython.py"
grep -q "UNKNOWN never guesses Python spelling" "$root/orxpython.cls"
grep -q "member('unknown')" "$root/name-projection-smoke.rex"
grep -q "def get_item(identity, key_identity)" "$root/orxpython.py"
grep -q "::method py.getItem" "$root/orxpython.cls"
grep -q "::method py.iter" "$root/orxpython.cls"
grep -q "object-protocol-ok" "$root/protocol-smoke.rex"
grep -q "def contains_object" "$root/orxpython.py"
grep -q "::method py.contains" "$root/orxpython.cls"
grep -q "::method py.eq" "$root/orxpython.cls"
grep -q "comparison-protocol-ok" "$root/comparison-smoke.rex"
grep -q "::method py.setMember" "$root/orxpython.cls"
grep -q "def set_member" "$root/orxpython.py"
grep -q "dynamic-method-mutation-ok" "$root/dynamic-method-smoke.rex"
grep -q "MethodType" "$root/dynamic-method-smoke.rex"
grep -q "dynamic-method-resolution-ok" "$root/dynamic-resolution-smoke.rex"
grep -q "Base~py.setMember" "$root/dynamic-resolution-smoke.rex"
grep -q "ChildClass~py.deleteMember" "$root/dynamic-resolution-smoke.rex"
echo "proxy-contract-ok"       
