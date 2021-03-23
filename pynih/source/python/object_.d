module python.object_;


struct PythonObject {
    import python.raw: PyObject;
    import std.traits: Unqual;

    private PyObject* _obj;

    invariant {
        assert(_obj !is null);
    }

    this(T)(auto ref T value) if(!is(Unqual!T == PyObject*)) {
        import python.conv.d_to_python: toPython;
        _obj = value.toPython;
    }

    // can only be used on Python C API calls that create a new PyObject*
    // due to reference count issues
    private this(PyObject* obj) {
        _obj = obj;
    }

    PythonObject str() const {
        return retPyObject!("PyObject_Str");
    }

    PythonObject repr() const {
        return retPyObject!("PyObject_Repr");
    }

    PythonObject bytes() const {
        return retPyObject!("PyObject_Bytes");
    }

    PythonObject type() const {
        return retPyObject!("PyObject_Type");
    }

    PythonObject dir() const {
        return retPyObject!("PyObject_Dir");
    }

    auto hash() const {
        return retDirect!"PyObject_Hash";
    }

    auto len() const {
        return retDirect!"PyObject_Length";
    }

    bool not() const {
        return cast(bool) retDirect!"PyObject_Not";
    }

    bool hasattr(in string attr) const {
        import std.string: toStringz;
        return cast(bool) retDirect!"PyObject_HasAttrString"(attr.toStringz);
    }

    bool hasattr(in PythonObject attr) const {
        return cast(bool) retDirect!"PyObject_HasAttr"(cast(PyObject*) attr._obj);
    }

    PythonObject getattr(in string attr) const {
        import std.string: toStringz;
        return retPyObject!"PyObject_GetAttrString"(attr.toStringz);
    }

    PythonObject getattr(in PythonObject attr) const {
        return retPyObject!"PyObject_GetAttr"(cast(PyObject*) attr._obj);
    }

    void setattr(T)(in string attr, auto ref T val) if(!is(Unqual!T == PythonObject)) {
        setattr(attr, PythonObject(val));
    }

    void setattr(in string attr, in PythonObject val) {
        import python.raw: PyObject_SetAttrString;
        import python.exception: PythonException;
        import std.string: toStringz;

        const res = PyObject_SetAttrString(cast(PyObject*) _obj, attr.toStringz, cast(PyObject*) val._obj);
        if(res == -1) throw new PythonException("Error setting attribute " ~ attr);
    }

    void setattr(T)(in PythonObject attr, auto ref T val) if(!is(Unqual!T == PythonObject)) {
        setattr(attr, PythonObject(val));
    }

    void setattr(in PythonObject attr, in PythonObject val) {
        import python.raw: PyObject_SetAttr;
        import python.exception: PythonException;

        const res = PyObject_SetAttr(cast(PyObject*) _obj, cast(PyObject*) attr._obj, cast(PyObject*) val._obj);
        if(res == -1) throw new PythonException("Error setting attribute ");

    }

    void delattr(in string attr) {
        import python.raw: PyObject_SetAttrString;
        import python.exception: PythonException;
        import std.string: toStringz;

        const res = PyObject_SetAttrString(cast(PyObject*) _obj, attr.toStringz, null);
        if(res == -1) throw new PythonException("Error setting attribute " ~ attr);
    }

    void delattr(in PythonObject attr) {
        import python.raw: PyObject_SetAttr;
        import python.exception: PythonException;

        const res = PyObject_SetAttr(cast(PyObject*) _obj, cast(PyObject*) attr._obj, null);
        if(res == -1) throw new PythonException("Error setting attribute ");
    }

    T to(T)() const {
        import python.conv.python_to_d: to;
        return (cast(PyObject*) _obj).to!T;
    }

    string toString() const {
        import python.raw: PyObject_Str;
        import python.conv.python_to_d: to;
        return PyObject_Str(cast(PyObject*) _obj).to!string;
    }

    int opCmp(in PythonObject other) const {
        import python.raw: PyObject_RichCompareBool, Py_LT, Py_EQ, Py_GT;
        import python.exception: PythonException;

        static int[int] pyOpToRet;
        if(pyOpToRet == pyOpToRet.init)
            pyOpToRet = [Py_LT: -1, Py_EQ: 0, Py_GT: 1];

        foreach(pyOp, ret; pyOpToRet) {
            const pyRes = PyObject_RichCompareBool(
                cast(PyObject*) _obj,
                cast(PyObject*) other._obj,
                pyOp
            );

            if(pyRes == -1)
                throw new PythonException("Error comparing Python objects");

            if(pyRes == 1)
                return ret;
        }

        assert(0);
    }

private:

    PythonObject retPyObject(string funcName, A...)(auto ref A args) const {
        import std.format: format;

        enum code = q{

            import python.exception: PythonException;
            import python.raw: %s;

            auto obj = %s(cast(PyObject*) _obj, args);
            if(obj is null) throw new PythonException("Failed to call %s");

            return PythonObject(obj);

        }.format(funcName, funcName, funcName);

        mixin(code);
    }

    auto retDirect(string cApiFunc, A...)(auto ref A args) const {

        import std.format: format;

        enum code = q{

            import python.exception: PythonException;
            import python.raw: %s;

            const ret = %s(cast(PyObject*) _obj, args);
            if(ret == -1)
                throw new PythonException("Could not call %s");

            return ret;

        }.format(cApiFunc, cApiFunc, cApiFunc);

        mixin(code);
    }
}
