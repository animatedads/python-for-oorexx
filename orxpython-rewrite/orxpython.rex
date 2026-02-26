::requires 'orxpython' library

::class 'Python' public
    ::attribute id get

    ::method init class
        call orxpython_InitializeInterpreter

    ::method uninit class
        call orxpython_FinalizeInterpreter

    ::method unknown class
        use strict arg name, args

        id = orxpython_CallFunction(name, args[1])
        return .Python~new(id)

    ::method init private
        expose id
        use strict arg id

    ::method uninit
        expose id
        call orxpython_DeleteObject id
