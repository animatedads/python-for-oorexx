#include <stdio.h>
#include <oorexxapi.h>
#define PY_SSIZE_T_CLEAN
#include <Python.h>

PyObject *pModule;
PyObject *pFuncCallFunction;
PyObject *pFuncDeleteObject;

RexxRoutine0(RexxObjectPtr, orxpython_InitializeInterpreter)
{
    Py_Initialize();

    CSTRING moduleName = "orxpython";
    pModule = PyImport_ImportModule(moduleName);

    if (pModule == NULL)
    {
        PyErr_Print();
        fprintf(stderr, "Failed to load \"%s\"\n", moduleName);
        fflush(stderr);
        // TODO: return 1;
    }
    else
    {
        pFuncCallFunction = PyObject_GetAttrString(pModule, "call_function");
        pFuncDeleteObject = PyObject_GetAttrString(pModule, "delete_object");
    }

    return NULLOBJECT;
}

RexxRoutine0(int, orxpython_FinalizeInterpreter)
{
    Py_DECREF(pFuncCallFunction);
    Py_DECREF(pFuncDeleteObject);
    Py_DECREF(pModule);

    return Py_FinalizeEx();
}

RexxRoutine2(uintptr_t, orxpython_CallFunction, CSTRING, name, CSTRING, arg)
{
    PyObject *pArgs, *pId;
    uintptr_t id;

    // Memory buffers for name and arg are copied.
    pArgs = Py_BuildValue("(ss)", name, arg);
    pId = PyObject_CallObject(pFuncCallFunction, pArgs);
    id = PyLong_AsUnsignedLongLong(pId);

    Py_DECREF(pArgs);
    Py_DECREF(pId);

    return id;
}

RexxRoutine1(RexxObjectPtr, orxpython_DeleteObject, uintptr_t, id)
{
    PyObject *pValue;

    // K: Convert a C unsigned long long to a Python integer object.
    pValue = PyObject_CallFunction(pFuncDeleteObject, "K", id);
    Py_DECREF(pValue);

    return NULLOBJECT;
}

RexxRoutineEntry orxpython_functions[] = {
    REXX_TYPED_ROUTINE(orxpython_InitializeInterpreter, orxpython_InitializeInterpreter),
    REXX_TYPED_ROUTINE(orxpython_FinalizeInterpreter, orxpython_FinalizeInterpreter),
    REXX_TYPED_ROUTINE(orxpython_CallFunction, orxpython_CallFunction),
    REXX_TYPED_ROUTINE(orxpython_DeleteObject, orxpython_DeleteObject),
    REXX_LAST_ROUTINE()
};

RexxPackageEntry orxpythonExternalRoutines_package_entry = {
    STANDARD_PACKAGE_HEADER
    REXX_CURRENT_INTERPRETER_VERSION, // ooRexx version at compilation time or higher
    "orxpythonExternalRoutines",      // name of the package
    "1.0.0",                          // package information
    NULL,                             // no load function
    NULL,                             // no unload function
    orxpython_functions,              // the exported routines
    NULL                              // the exported methods
};

// package loading stub.
OOREXX_GET_PACKAGE(orxpythonExternalRoutines);
