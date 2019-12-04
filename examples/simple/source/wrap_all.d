module wrap_all;

import templates2;
import impl: OtherString;

// should be registered in Python as identity_int
alias identityInt = identity!int;

int product(int i, int j) {
    return i * j;
}

struct String {
    string s;
    this(string s) { this.s = s; }
}


string otherStringAsParam(OtherString s) {
    return s.s ~ "quux";
}


enum MyEnum {
    foo,
    bar,
    baz,
}


// FIXME
// See https://github.com/symmetryinvestments/autowrap/issues/177
version(Have_autowrap_csharp) {}
else {

    // mimics std.range.chain
    auto mychain(Ranges...)(Ranges ranges) {

        static struct Oops {
            import std.meta: staticMap;
            import std.traits: Unqual;
            alias R = staticMap!(Unqual, Ranges);
        }

        return Oops();
    }


    auto chainy() {
        import std.range: iota;
        return mychain(5.iota, 7.iota);

    }
}


struct HasOnlyOpIndex {
    bool opIndex(size_t i) @safe @nogc pure nothrow const {
        return i == 42;
    }
}
