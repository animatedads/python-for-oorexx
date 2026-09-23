/*
 * orxpython.cpp - Native ooRexx package for the orxpython rewrite.
 *
 * This file is intentionally a thin boundary.  ooRexx calls typed native
 * routines here; the routines translate primitive ABI values to CPython calls
 * implemented by orxpython.py.  Python object semantics and object ownership
 * remain in that Python module rather than being duplicated in C++.
 *
 * Object identities crossing into Rexx are opaque uintptr_t values.  They are
 * keys into the Python-side registry; they are never dereferenced by Rexx.
 *
 * CPython ownership rule used here:
 *   - helper function objects cached from the module are owned references;
 *   - temporary argument/result objects are released in the routine that
 *     creates them;
 *   - ordinary Python failures cross the boundary as ooRexx Error 93.900
 *     conditions carrying the Python exception type and message.
 *
 * Identity zero remains reserved for protocol sentinels (notably iterator
 * exhaustion); it is never used to hide an active Python exception.
 */

#include <cstdint>
#include <cstdarg>
#include <cstdio>
#include <string>
#include <oorexxapi.h>

#define PY_SSIZE_T_CLEAN
#include <Python.h>

static uintptr_t pythonFailureAsRexx(RexxCallContext *context);

namespace {
PyObject *module = nullptr;
PyObject *callFunction = nullptr;
PyObject *deleteObject = nullptr;
PyObject *importModule = nullptr;
PyObject *getMember = nullptr;
PyObject *callObject = nullptr;
PyObject *makeInt = nullptr;
PyObject *makeString = nullptr;
PyObject *reprObject = nullptr;
PyObject *makeNone = nullptr;
PyObject *makeBool = nullptr;
PyObject *scalarKind = nullptr;
PyObject *scalarText = nullptr;
PyObject *typeObject = nullptr;
PyObject *exactTypeIs = nullptr;
PyObject *isInstance = nullptr;
PyObject *isSubclass = nullptr;
PyObject *callObjectKw = nullptr;
PyObject *getMemberRexx = nullptr;
PyObject *getItem = nullptr;
PyObject *setItem = nullptr;
PyObject *objectLength = nullptr;
PyObject *objectTruth = nullptr;
PyObject *iterObject = nullptr;
PyObject *nextObject = nullptr;
PyObject *containsObject = nullptr;
PyObject *compareObjects = nullptr;
PyObject *setMember = nullptr;
PyObject *deleteMember = nullptr;
PyObject *hasMember = nullptr;
PyObject *sameObject = nullptr;

/* Load and retain one callable helper from orxpython.py.
 *
 * Initialization calls this once per bridge operation.  A missing or
 * non-callable helper is reported as a Python exception so the normal
 * boundary translator can give Rexx a useful condition.
 */
PyObject *loadHelper(const char *name)
{
    PyObject *helper = PyObject_GetAttrString(module, name);
    if (helper == nullptr || !PyCallable_Check(helper)) {
        Py_XDECREF(helper);
        PyErr_Format(PyExc_RuntimeError, "orxpython.%s is not callable", name);
        return nullptr;
    }
    return helper;
}

/* Convert a Python helper result into the opaque identity returned to Rexx.
 * The helper result is an owned reference and is always consumed here.
 */
uintptr_t identityFromResult(RexxCallContext *context, PyObject *result)
{
    if (result == nullptr) return pythonFailureAsRexx(context);

    const unsigned long long value = PyLong_AsUnsignedLongLong(result);
    Py_DECREF(result);
    if (PyErr_Occurred()) return pythonFailureAsRexx(context);
    return static_cast<uintptr_t>(value);
}

/* Call a helper whose successful result is a registry identity.
 * Keeping tuple construction and result conversion here makes the small typed
 * Rexx entry points below uniform and keeps CPython ownership in one place.
 */
uintptr_t callIdentityHelper(RexxCallContext *context, PyObject *helper, const char *format, ...)
{
    if (helper == nullptr) {
        return 0;
    }

    va_list args;
    va_start(args, format);
    PyObject *arguments = Py_VaBuildValue(format, args);
    va_end(args);
    if (arguments == nullptr) return pythonFailureAsRexx(context);

    /* PyObject_CallObject requires a tuple.  "(...)" formats below provide it. */
    PyObject *result = PyObject_CallObject(helper, arguments);
    Py_DECREF(arguments);
    return identityFromResult(context, result);
}
}

/* Start embedded Python and cache the Python-side bridge operations.
 * This routine is idempotent with respect to an already-running interpreter;
 * helper lookup failures are translated after all lookups have been attempted.
 */
RexxRoutine0(RexxObjectPtr, orxpython_InitializeInterpreter)
{
    if (!Py_IsInitialized()) {
        Py_Initialize();
    }

    module = PyImport_ImportModule("orxpython");
    if (module == nullptr) {
        PyErr_Print();
        return NULLOBJECT;
    }

    callFunction = loadHelper("call_function");
    deleteObject = loadHelper("delete_object");
    importModule = loadHelper("import_module");
    getMember = loadHelper("get_member");
    callObject = loadHelper("call_object");
    makeInt = loadHelper("make_int");
    makeString = loadHelper("make_string");
    reprObject = loadHelper("repr_object");
    makeNone = loadHelper("make_none");
    makeBool = loadHelper("make_bool");
    scalarKind = loadHelper("scalar_kind");
    scalarText = loadHelper("scalar_text");
    typeObject = loadHelper("type_object");
    exactTypeIs = loadHelper("exact_type_is");
    isInstance = loadHelper("is_instance");
    isSubclass = loadHelper("is_subclass");
    callObjectKw = loadHelper("call_object_kw");
    getMemberRexx = loadHelper("get_member_rexx");
    getItem = loadHelper("get_item");
    setItem = loadHelper("set_item");
    objectLength = loadHelper("object_length");
    objectTruth = loadHelper("object_truth");
    iterObject = loadHelper("iter_object");
    nextObject = loadHelper("next_object");
    containsObject = loadHelper("contains_object");
    compareObjects = loadHelper("compare_objects");
    setMember = loadHelper("set_member");
    deleteMember = loadHelper("delete_member");
    hasMember = loadHelper("has_member");
    sameObject = loadHelper("same_object");

    if (PyErr_Occurred()) pythonFailureAsRexx(context);
    return NULLOBJECT;
}

/* Release cached helper references before finalizing CPython.
 * Py_CLEAR makes repeated/partial initialization cleanup safe.
 */
RexxRoutine0(int, orxpython_FinalizeInterpreter)
{
    Py_CLEAR(callFunction);
    Py_CLEAR(deleteObject);
    Py_CLEAR(importModule);
    Py_CLEAR(getMember);
    Py_CLEAR(callObject);
    Py_CLEAR(makeInt);
    Py_CLEAR(makeString);
    Py_CLEAR(reprObject);
    Py_CLEAR(makeNone);
    Py_CLEAR(makeBool);
    Py_CLEAR(scalarKind);
    Py_CLEAR(scalarText);
    Py_CLEAR(typeObject);
    Py_CLEAR(exactTypeIs);
    Py_CLEAR(isInstance);
    Py_CLEAR(isSubclass);
    Py_CLEAR(callObjectKw);
    Py_CLEAR(getMemberRexx);
    Py_CLEAR(getItem);
    Py_CLEAR(setItem);
    Py_CLEAR(objectLength);
    Py_CLEAR(objectTruth);
    Py_CLEAR(iterObject);
    Py_CLEAR(nextObject);
    Py_CLEAR(containsObject);
    Py_CLEAR(compareObjects);
    Py_CLEAR(setMember);
    Py_CLEAR(deleteMember);
    Py_CLEAR(hasMember);
    Py_CLEAR(sameObject);
    Py_CLEAR(module);
    return Py_IsInitialized() ? Py_FinalizeEx() : 0;
}

RexxRoutine2(uintptr_t, orxpython_CallFunction, CSTRING, name, CSTRING, argument)
{
    return callIdentityHelper(context, callFunction, "(ss)", name, argument);
}

RexxRoutine1(uintptr_t, orxpython_ImportModule, CSTRING, name)
{
    return callIdentityHelper(context, importModule, "(s)", name);
}

RexxRoutine2(uintptr_t, orxpython_GetMember, uintptr_t, identity, CSTRING, name)
{
    return callIdentityHelper(context, getMember, "(Ks)", static_cast<unsigned long long>(identity), name);
}


RexxRoutine2(uintptr_t, orxpython_GetMemberRexx, uintptr_t, identity, CSTRING, name)
{
    return callIdentityHelper(
        context, getMemberRexx, "(Ks)", static_cast<unsigned long long>(identity), name);
}

/* Marshal a Rexx Array of proxy identities and invoke a Python callable. */
RexxRoutine2(uintptr_t, orxpython_CallObject, uintptr_t, identity, RexxArrayObject, args)
{
    const size_t count = context->ArrayItems(args);
    PyObject *list = PyList_New(static_cast<Py_ssize_t>(count));
    if (list == nullptr) return pythonFailureAsRexx(context);

    for (size_t index = 1; index <= count; ++index) {
        RexxObjectPtr item = context->ArrayAt(args, index);
        uint64_t value = 0;
        if (!context->UnsignedInt64(item, &value)) {
            Py_DECREF(list);
            return 0;
        }
        PyObject *number = PyLong_FromUnsignedLongLong(value);
        if (number == nullptr) {
            Py_DECREF(list);
            return pythonFailureAsRexx(context);
        }
        PyList_SET_ITEM(list, static_cast<Py_ssize_t>(index - 1), number);
    }

    PyObject *arguments = Py_BuildValue("(KO)", static_cast<unsigned long long>(identity), list);
    Py_DECREF(list);
    if (arguments == nullptr) return pythonFailureAsRexx(context);
    PyObject *result = PyObject_CallObject(callObject, arguments);
    Py_DECREF(arguments);
    return identityFromResult(context, result);
}


static uintptr_t pythonFailureAsRexx(RexxCallContext *context)
{
    /*
     * Preserve the Python exception's type and message at the language
     * boundary.  Error 93.900 is used as the ooRexx carrier; Python remains
     * authoritative for the underlying exception class and text.
     */
    PyObject *type = nullptr;
    PyObject *value = nullptr;
    PyObject *traceback = nullptr;
    PyErr_Fetch(&type, &value, &traceback);
    PyErr_NormalizeException(&type, &value, &traceback);

    const char *typeName = "PythonException";
    if (type != nullptr) {
        PyObject *name = PyObject_GetAttrString(type, "__name__");
        if (name != nullptr) {
            const char *candidate = PyUnicode_AsUTF8(name);
            if (candidate != nullptr) typeName = candidate;
        }
        /* typeName is copied below before name is released. */
        PyObject *messageObject = value == nullptr ? nullptr : PyObject_Str(value);
        const char *message = messageObject == nullptr ? "" : PyUnicode_AsUTF8(messageObject);
        std::string text(typeName);
        if (message != nullptr && *message != '\0') {
            text += ": ";
            text += message;
        }
        Py_XDECREF(messageObject);
        Py_XDECREF(name);
        Py_XDECREF(type);
        Py_XDECREF(value);
        Py_XDECREF(traceback);
        context->RaiseException1(93900, context->NewStringFromAsciiz(text.c_str()));
        return 0;
    }

    Py_XDECREF(type);
    Py_XDECREF(value);
    Py_XDECREF(traceback);
    context->RaiseException1(
        93900, context->NewStringFromAsciiz("Python operation failed"));
    return 0;
}


RexxRoutine4(uintptr_t, orxpython_CallObjectKw,
             uintptr_t, identity,
             RexxArrayObject, positionalIds,
             RexxArrayObject, keywordNames,
             RexxArrayObject, keywordIds)
{
    auto makeIdList = [context](RexxArrayObject source) -> PyObject * {
        const size_t count = context->ArrayItems(source);
        PyObject *list = PyList_New(static_cast<Py_ssize_t>(count));
        if (list == nullptr) return nullptr;
        for (size_t index = 1; index <= count; ++index) {
            uint64_t value = 0;
            if (!context->UnsignedInt64(context->ArrayAt(source, index), &value)) {
                Py_DECREF(list);
                return nullptr;
            }
            PyObject *number = PyLong_FromUnsignedLongLong(value);
            if (number == nullptr) {
                Py_DECREF(list);
                return nullptr;
            }
            PyList_SET_ITEM(list, static_cast<Py_ssize_t>(index - 1), number);
        }
        return list;
    };

    PyObject *positional = makeIdList(positionalIds);
    PyObject *values = makeIdList(keywordIds);
    if (positional == nullptr || values == nullptr) {
        Py_XDECREF(positional);
        Py_XDECREF(values);
        if (PyErr_Occurred()) return pythonFailureAsRexx(context);
        return 0;
    }

    const size_t keywordCount = context->ArrayItems(keywordNames);
    PyObject *names = PyList_New(static_cast<Py_ssize_t>(keywordCount));
    if (names == nullptr) {
        Py_DECREF(positional);
        Py_DECREF(values);
        return pythonFailureAsRexx(context);
    }
    for (size_t index = 1; index <= keywordCount; ++index) {
        RexxStringObject stringObject =
            context->ObjectToString(context->ArrayAt(keywordNames, index));
        const char *name = context->CString(stringObject);
        PyObject *pythonName = PyUnicode_FromString(name);
        if (pythonName == nullptr) {
            Py_DECREF(positional);
            Py_DECREF(values);
            Py_DECREF(names);
            return pythonFailureAsRexx(context);
        }
        PyList_SET_ITEM(names, static_cast<Py_ssize_t>(index - 1), pythonName);
    }

    PyObject *arguments = Py_BuildValue(
        "(KOOO)", static_cast<unsigned long long>(identity),
        positional, names, values);
    Py_DECREF(positional);
    Py_DECREF(names);
    Py_DECREF(values);
    if (arguments == nullptr) return pythonFailureAsRexx(context);

    PyObject *result = PyObject_CallObject(callObjectKw, arguments);
    Py_DECREF(arguments);
    if (result == nullptr) return pythonFailureAsRexx(context);
    return identityFromResult(context, result);
}

RexxRoutine1(uintptr_t, orxpython_MakeInt, int64_t, value)
{
    return callIdentityHelper(context, makeInt, "(L)", static_cast<long long>(value));
}

RexxRoutine1(uintptr_t, orxpython_MakeString, CSTRING, value)
{
    return callIdentityHelper(context, makeString, "(s)", value);
}

RexxRoutine1(RexxStringObject, orxpython_Repr, uintptr_t, identity)
{
    PyObject *arguments = Py_BuildValue("(K)", static_cast<unsigned long long>(identity));
    if (arguments == nullptr) {
        pythonFailureAsRexx(context);
        return context->NewStringFromAsciiz("");
    }
    PyObject *result = PyObject_CallObject(reprObject, arguments);
    Py_DECREF(arguments);
    if (result == nullptr) {
        pythonFailureAsRexx(context);
        return context->NewStringFromAsciiz("");
    }
    const char *text = PyUnicode_AsUTF8(result);
    if (text == nullptr) {
        Py_DECREF(result);
        pythonFailureAsRexx(context);
        return context->NewStringFromAsciiz("");
    }
    RexxStringObject answer = context->NewStringFromAsciiz(text);
    Py_DECREF(result);
    return answer;
}


RexxRoutine0(uintptr_t, orxpython_MakeNone)
{
    return callIdentityHelper(context, makeNone, "()");
}

RexxRoutine1(uintptr_t, orxpython_MakeBool, int, value)
{
    return callIdentityHelper(context, makeBool, "(i)", value != 0);
}

RexxRoutine1(RexxStringObject, orxpython_ScalarKind, uintptr_t, identity)
{
    PyObject *result = PyObject_CallFunction(
        scalarKind, "K", static_cast<unsigned long long>(identity));
    if (result == nullptr) {
        pythonFailureAsRexx(context);
        return context->NewStringFromAsciiz("");
    }
    const char *text = PyUnicode_AsUTF8(result);
    RexxStringObject answer = text == nullptr
        ? context->NewStringFromAsciiz("")
        : context->NewStringFromAsciiz(text);
    Py_DECREF(result);
    return answer;
}

RexxRoutine1(RexxStringObject, orxpython_ScalarText, uintptr_t, identity)
{
    PyObject *result = PyObject_CallFunction(
        scalarText, "K", static_cast<unsigned long long>(identity));
    if (result == nullptr) {
        pythonFailureAsRexx(context);
        return context->NewStringFromAsciiz("");
    }
    const char *text = PyUnicode_AsUTF8(result);
    RexxStringObject answer = text == nullptr
        ? context->NewStringFromAsciiz("")
        : context->NewStringFromAsciiz(text);
    Py_DECREF(result);
    return answer;
}


RexxRoutine1(uintptr_t, orxpython_TypeObject, uintptr_t, identity)
{
    return callIdentityHelper(
        context, typeObject, "(K)", static_cast<unsigned long long>(identity));
}

/* Call a Python predicate helper without conflating false with failure. */
static int callRelation(RexxCallContext *context, PyObject *helper, uintptr_t left, uintptr_t right)
{
    PyObject *result = PyObject_CallFunction(
        helper, "KK",
        static_cast<unsigned long long>(left),
        static_cast<unsigned long long>(right));
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    const int truth = PyObject_IsTrue(result);
    Py_DECREF(result);
    if (truth < 0) return static_cast<int>(pythonFailureAsRexx(context));
    return truth;
}

RexxRoutine2(int, orxpython_ExactTypeIs, uintptr_t, identity, uintptr_t, classIdentity)
{
    return callRelation(context, exactTypeIs, identity, classIdentity);
}

RexxRoutine2(int, orxpython_IsInstance, uintptr_t, identity, uintptr_t, classIdentity)
{
    return callRelation(context, isInstance, identity, classIdentity);
}

RexxRoutine2(int, orxpython_IsSubclass, uintptr_t, classIdentity, uintptr_t, superclassIdentity)
{
    return callRelation(context, isSubclass, classIdentity, superclassIdentity);
}


RexxRoutine2(uintptr_t, orxpython_GetItem, uintptr_t, identity, uintptr_t, keyIdentity)
{
    return callIdentityHelper(
        context, getItem, "(KK)",
        static_cast<unsigned long long>(identity),
        static_cast<unsigned long long>(keyIdentity));
}

RexxRoutine3(int, orxpython_SetItem, uintptr_t, identity, uintptr_t, keyIdentity,
             uintptr_t, valueIdentity)
{
    PyObject *result = PyObject_CallFunction(
        setItem, "KKK",
        static_cast<unsigned long long>(identity),
        static_cast<unsigned long long>(keyIdentity),
        static_cast<unsigned long long>(valueIdentity));
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    Py_DECREF(result);
    return 1;
}

RexxRoutine1(uint64_t, orxpython_Length, uintptr_t, identity)
{
    PyObject *result = PyObject_CallFunction(
        objectLength, "K", static_cast<unsigned long long>(identity));
    if (result == nullptr) return static_cast<uint64_t>(pythonFailureAsRexx(context));
    const unsigned long long value = PyLong_AsUnsignedLongLong(result);
    Py_DECREF(result);
    if (PyErr_Occurred()) return static_cast<uint64_t>(pythonFailureAsRexx(context));
    return static_cast<uint64_t>(value);
}

RexxRoutine1(int, orxpython_Truth, uintptr_t, identity)
{
    PyObject *result = PyObject_CallFunction(
        objectTruth, "K", static_cast<unsigned long long>(identity));
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    const int truth = PyObject_IsTrue(result);
    Py_DECREF(result);
    if (truth < 0) return static_cast<int>(pythonFailureAsRexx(context));
    return truth;
}

RexxRoutine1(uintptr_t, orxpython_Iter, uintptr_t, identity)
{
    return callIdentityHelper(
        context, iterObject, "(K)", static_cast<unsigned long long>(identity));
}

RexxRoutine1(uintptr_t, orxpython_Next, uintptr_t, identity)
{
    return callIdentityHelper(
        context, nextObject, "(K)", static_cast<unsigned long long>(identity));
}


RexxRoutine2(int, orxpython_Contains, uintptr_t, identity, uintptr_t, candidateIdentity)
{
    return callRelation(context, containsObject, identity, candidateIdentity);
}

RexxRoutine3(int, orxpython_Compare, uintptr_t, leftIdentity, CSTRING, operatorName,
             uintptr_t, rightIdentity)
{
    PyObject *result = PyObject_CallFunction(
        compareObjects, "KsK",
        static_cast<unsigned long long>(leftIdentity), operatorName,
        static_cast<unsigned long long>(rightIdentity));
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    const int truth = PyObject_IsTrue(result);
    Py_DECREF(result);
    if (truth < 0) return static_cast<int>(pythonFailureAsRexx(context));
    return truth;
}


RexxRoutine3(int, orxpython_SetMember, uintptr_t, identity, CSTRING, name, uintptr_t, valueIdentity)
{
    PyObject *result = PyObject_CallFunction(
        setMember, "KsK",
        static_cast<unsigned long long>(identity), name,
        static_cast<unsigned long long>(valueIdentity));
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    Py_DECREF(result);
    return 1;
}
RexxRoutine2(int, orxpython_DeleteMember, uintptr_t, identity, CSTRING, name)
{
    PyObject *result = PyObject_CallFunction(
        deleteMember, "Ks", static_cast<unsigned long long>(identity), name);
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    Py_DECREF(result);
    return 1;
}
RexxRoutine2(int, orxpython_HasMember, uintptr_t, identity, CSTRING, name)
{
    PyObject *result = PyObject_CallFunction(
        hasMember, "Ks", static_cast<unsigned long long>(identity), name);
    if (result == nullptr) return static_cast<int>(pythonFailureAsRexx(context));
    const int truth = PyObject_IsTrue(result);
    Py_DECREF(result);
    if (truth < 0) return static_cast<int>(pythonFailureAsRexx(context));
    return truth;
}
RexxRoutine2(int, orxpython_SameObject, uintptr_t, leftIdentity, uintptr_t, rightIdentity)
{
    return callRelation(context, sameObject, leftIdentity, rightIdentity);
}
RexxRoutine1(RexxObjectPtr, orxpython_DeleteObject, uintptr_t, identity)
{
    if (deleteObject == nullptr) {
        return NULLOBJECT;
    }
    PyObject *result = PyObject_CallFunction(
        deleteObject, "K", static_cast<unsigned long long>(identity));
    if (result == nullptr) {
        /* Destructors must not raise into ooRexx during GC/finalization. */
        PyErr_Clear();
    }
    Py_XDECREF(result);
    return NULLOBJECT;
}

RexxRoutineEntry orxpython_functions[] = {
    REXX_TYPED_ROUTINE(orxpython_InitializeInterpreter, orxpython_InitializeInterpreter),
    REXX_TYPED_ROUTINE(orxpython_FinalizeInterpreter, orxpython_FinalizeInterpreter),
    REXX_TYPED_ROUTINE(orxpython_CallFunction, orxpython_CallFunction),
    REXX_TYPED_ROUTINE(orxpython_ImportModule, orxpython_ImportModule),
    REXX_TYPED_ROUTINE(orxpython_GetMember, orxpython_GetMember),
    REXX_TYPED_ROUTINE(orxpython_GetMemberRexx, orxpython_GetMemberRexx),
    REXX_TYPED_ROUTINE(orxpython_CallObject, orxpython_CallObject),
    REXX_TYPED_ROUTINE(orxpython_CallObjectKw, orxpython_CallObjectKw),
    REXX_TYPED_ROUTINE(orxpython_MakeInt, orxpython_MakeInt),
    REXX_TYPED_ROUTINE(orxpython_MakeString, orxpython_MakeString),
    REXX_TYPED_ROUTINE(orxpython_Repr, orxpython_Repr),
    REXX_TYPED_ROUTINE(orxpython_MakeNone, orxpython_MakeNone),
    REXX_TYPED_ROUTINE(orxpython_MakeBool, orxpython_MakeBool),
    REXX_TYPED_ROUTINE(orxpython_ScalarKind, orxpython_ScalarKind),
    REXX_TYPED_ROUTINE(orxpython_ScalarText, orxpython_ScalarText),
    REXX_TYPED_ROUTINE(orxpython_TypeObject, orxpython_TypeObject),
    REXX_TYPED_ROUTINE(orxpython_ExactTypeIs, orxpython_ExactTypeIs),
    REXX_TYPED_ROUTINE(orxpython_IsInstance, orxpython_IsInstance),
    REXX_TYPED_ROUTINE(orxpython_IsSubclass, orxpython_IsSubclass),
    REXX_TYPED_ROUTINE(orxpython_GetItem, orxpython_GetItem),
    REXX_TYPED_ROUTINE(orxpython_SetItem, orxpython_SetItem),
    REXX_TYPED_ROUTINE(orxpython_Length, orxpython_Length),
    REXX_TYPED_ROUTINE(orxpython_Truth, orxpython_Truth),
    REXX_TYPED_ROUTINE(orxpython_Iter, orxpython_Iter),
    REXX_TYPED_ROUTINE(orxpython_Next, orxpython_Next),
    REXX_TYPED_ROUTINE(orxpython_Contains, orxpython_Contains),
    REXX_TYPED_ROUTINE(orxpython_Compare, orxpython_Compare),
    REXX_TYPED_ROUTINE(orxpython_SetMember, orxpython_SetMember),
    REXX_TYPED_ROUTINE(orxpython_DeleteMember, orxpython_DeleteMember),
    REXX_TYPED_ROUTINE(orxpython_HasMember, orxpython_HasMember),
    REXX_TYPED_ROUTINE(orxpython_SameObject, orxpython_SameObject),
    REXX_TYPED_ROUTINE(orxpython_DeleteObject, orxpython_DeleteObject),
    REXX_LAST_ROUTINE()
};

RexxPackageEntry orxpythonExternalRoutines_package_entry = {
    STANDARD_PACKAGE_HEADER
    REXX_CURRENT_INTERPRETER_VERSION,
    "orxpythonExternalRoutines",
    "1.0.0",
    NULL,
    NULL,
    orxpython_functions,
    NULL
};

OOREXX_GET_PACKAGE(orxpythonExternalRoutines);
