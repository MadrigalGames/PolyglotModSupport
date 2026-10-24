module basis;
import basis::bindings;
import std::hash::murmur3;

alias StringHash = uint;

fn InteropString toInteropString(String str)
{
	return { str, str.len };
}

fn String fromInteropString(InteropString* interop)
{
	return (String)interop.ptr[:interop.len];
}

// This needs to match the seed used on the C++/C# side.
const uint HASH_SEED = 0;

fn StringHash makeStringHash(String str)
{
	return murmur3::hash32(str, HASH_SEED);
}
