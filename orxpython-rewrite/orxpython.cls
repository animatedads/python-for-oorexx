/*
 * orxpython.cls - Rexx proxy surface for the orxpython rewrite.
 *
 * A .PythonObject contains only an opaque identity owned by orxpython.py.
 * Attribute lookup and callable invocation are delegated back to Python so
 * descriptors and bound/class methods use Python's own rules.
 */
::requires 'orxpython' library

::class 'Python' public
    ::method init class
        call orxpython_InitializeInterpreter

    ::method uninit class
        call orxpython_FinalizeInterpreter

    /* Construct proxies for modules and exact built-in values. */
    ::method import class
        use strict arg name
        return .PythonObject~new(orxpython_ImportModule(name))

    ::method int class
        use strict arg value
        return .PythonObject~new(orxpython_MakeInt(value))

    ::method string class
        use strict arg value
        return .PythonObject~new(orxpython_MakeString(value))

    ::method none class
        return .PythonObject~new(orxpython_MakeNone())

    ::method bool class
        use strict arg value
        return .PythonObject~new(orxpython_MakeBool(value))

    ::method kwd class
        use strict arg name, value
        if \ value~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python keyword value must be a PythonObject proxy')
        return .PythonKeywordArgument~new(name, value)

    /* Retain Kaan's initial prototype UNKNOWN behaviour. */
    ::method unknown class
        use strict arg name, args
        id = orxpython_CallFunction(name, args[1])
        return .PythonObject~new(id)

::class 'PythonObject' public
    ::attribute id get

    ::method init
        expose id
        use strict arg id
        if id == 0 then raise syntax 93.900 array('Python bridge operation failed')
        /* 'use strict arg id' assigns the exposed instance variable directly. */

    ::method uninit
        expose id
        if id \== .nil then call orxpython_DeleteObject id

    /* Exact-name escape hatch; bypasses Rexx selector projection. */
    ::method member
        expose id
        use strict arg name
        return .PythonObject~new(orxpython_GetMember(id, name))

    ::method call
        expose id

        /*
         * Rexx message arguments are separate arguments, not an implicit
         * Array.  Materialize them explicitly before crossing the native ABI.
         * This also preserves a zero-argument Python call as an empty Array.
         */
        objects = arg(1, 'Array')
        ids = .Array~new
        do object over objects
            if \ object~isInstanceOf(.PythonObject) then
                raise syntax 93.900 array('Python call arguments must be PythonObject proxies')
            ids~append(object~id)
        end

        return .PythonObject~new(orxpython_CallObject(id, ids))

    ::method callKw
        expose id

        /*
         * Keyword arguments are explicit wrapper objects.  This avoids
         * guessing whether an ordinary Python dict is intended as a positional
         * argument or as the Rexx representation of **kwargs.
         */
        supplied = arg(1, 'Array')
        positionalIds = .Array~new
        keywordNames = .Array~new
        keywordIds = .Array~new

        do item over supplied
            if item~isInstanceOf(.PythonKeywordArgument) then do
                keywordNames~append(item~name)
                keywordIds~append(item~value~id)
            end
            else do
                if \ item~isInstanceOf(.PythonObject) then
                    raise syntax 93.900 array('Python call arguments must be PythonObject proxies')
                positionalIds~append(item~id)
            end
        end

        return .PythonObject~new(orxpython_CallObjectKw(id, positionalIds, keywordNames, keywordIds))

    ::method repr
        expose id
        return orxpython_Repr(id)

    ::method unknown
        expose id
        use strict arg name, args

        /*
         * Rexx UNKNOWN supplies the message arguments as an Array.  A message
         * with no arguments denotes Python attribute access.  A message with
         * arguments denotes lookup followed by positional invocation.
         *
         * The exact Python spelling is recovered through a per-object selector
         * projection.  Colliding, dynamic, or reserved selectors use the
         * explicit member(name) path; UNKNOWN never guesses Python spelling.
         * This is local bridge machinery and has no external object dependency.
         */
        member = .PythonObject~new(orxpython_GetMemberRexx(id, name))
        if args~items == 0 then
            return member

        ids = .Array~new
        do object over args
            if \ object~isInstanceOf(.PythonObject) then
                raise syntax 93.900 array('Python call arguments must be PythonObject proxies')
            ids~append(object~id)
        end
        return .PythonObject~new(orxpython_CallObject(member~id, ids))

    /* Explicit Python object/container protocol operations. */
    ::method py.getItem
        expose id
        use strict arg key
        if \ key~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python subscription key must be a PythonObject proxy')
        return .PythonObject~new(orxpython_GetItem(id, key~id))

    ::method py.setItem
        expose id
        use strict arg key, value
        if \ key~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python subscription key must be a PythonObject proxy')
        if \ value~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python subscription value must be a PythonObject proxy')
        if orxpython_SetItem(id, key~id, value~id) \== 1 then
            raise syntax 93.900 array('Python subscription assignment failed')
        return self

    ::method py.length
        expose id
        return orxpython_Length(id)

    ::method py.truth
        expose id
        return orxpython_Truth(id) == 1

    ::method py.iter
        expose id
        return .PythonObject~new(orxpython_Iter(id))

    ::method py.next
        expose id
        nextId = orxpython_Next(id)
        if nextId == 0 then return .nil
        return .PythonObject~new(nextId)

    ::method py.contains
        expose id
        use strict arg candidate
        if \ candidate~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python containment candidate must be a PythonObject proxy')
        return orxpython_Contains(id, candidate~id) == 1

    ::method py.eq
        expose id
        use strict arg other
        return self~py.compare('eq', other)

    ::method py.ne
        expose id
        use strict arg other
        return self~py.compare('ne', other)

    ::method py.lt
        expose id
        use strict arg other
        return self~py.compare('lt', other)

    ::method py.le
        expose id
        use strict arg other
        return self~py.compare('le', other)

    ::method py.gt
        expose id
        use strict arg other
        return self~py.compare('gt', other)

    ::method py.ge
        expose id
        use strict arg other
        return self~py.compare('ge', other)

    ::method py.compare private
        expose id
        use strict arg operator, other
        if \ other~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python comparison operand must be a PythonObject proxy')
        return orxpython_Compare(id, operator, other~id) == 1

    /* Exact attribute mutation and identity; Python owns descriptor rules. */
    ::method py.setMember
        expose id
        use strict arg name, value
        if \ value~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python attribute value must be a PythonObject proxy')
        if orxpython_SetMember(id, name, value~id) \== 1 then
            raise syntax 93.900 array('Python attribute assignment failed')
        return self
    ::method py.deleteMember
        expose id
        use strict arg name
        if orxpython_DeleteMember(id, name) \== 1 then
            raise syntax 93.900 array('Python attribute deletion failed')
        return self
    ::method py.hasMember
        expose id
        use strict arg name
        return orxpython_HasMember(id, name) == 1
    ::method py.is
        expose id
        use strict arg other
        if \ other~isInstanceOf(.PythonObject) then
            raise syntax 93.900 array('Python identity operand must be a PythonObject proxy')
        return orxpython_SameObject(id, other~id) == 1

    /* Python-authoritative type and inheritance relations. */
    ::method py.type
        expose id
        return .PythonObject~new(orxpython_TypeObject(id))

    ::method py.exactTypeIs
        expose id
        use strict arg pythonClass
        return orxpython_ExactTypeIs(id, pythonClass~id) == 1

    ::method py.isInstanceOf
        expose id
        use strict arg pythonClass
        return orxpython_IsInstance(id, pythonClass~id) == 1

    ::method py.isSubclassOf
        expose id
        use strict arg pythonSuperclass
        return orxpython_IsSubclass(id, pythonSuperclass~id) == 1

    /* Lossless conversion is limited to exact Python built-in scalars. */
    ::method scalarKind
        expose id
        return orxpython_ScalarKind(id)

    ::method scalar
        expose id
        kind = orxpython_ScalarKind(id)

        select
            when kind == 'none' then return .nil
            when kind == 'bool' then return orxpython_ScalarText(id) == '1'
            when kind == 'int' then return orxpython_ScalarText(id) + 0
            when kind == 'float' then return orxpython_ScalarText(id) + 0
            when kind == 'str' then return orxpython_ScalarText(id)
            otherwise raise syntax 93.900 array('Python object is not a built-in scalar')
        end


::class 'PythonKeywordArgument'
    ::attribute name get
    ::attribute value get

    ::method init
        expose name value
        use strict arg name, value
