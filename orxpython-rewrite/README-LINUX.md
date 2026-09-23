# orxpython rewrite — portable qualification package

This package is a development/qualification snapshot of the `orxpython-rewrite`
work.  It keeps Python object semantics in Python, uses opaque registry
identities at the ooRexx/native boundary, and discovers ooRexx/Python build
locations rather than assuming a single desktop installation layout.

The source comments focus on ownership and boundary contracts: Python owns
attribute lookup, descriptors, MRO, comparison and dynamic method behaviour;
`orxpython.py` owns strong references for Rexx proxies; C++ owns only its cached
helper and temporary CPython references; Python exceptions cross to ooRexx as
Error 93.900 rather than being confused with valid false/zero results.

Run `./check-source.sh`, then `./build-linux.sh` and `./test-linux.sh`.  The
scripts accept explicit `OOREXX_ROOT` / `REXX_HOME`, `OOREXX_SOURCE_ROOT`,
`OOREXX_BUILD_ROOT`, `REXX`, `PYTHON`, and `BUILD_DIR` overrides and also probe
common installed/source-build layouts, including Termux-style source/build
splits.

This snapshot is qualification material, not a request to replace an upstream
maintainer's tree wholesale.  Upstream contribution should be made as a small,
reviewable diff against the maintainer's current `main`.
