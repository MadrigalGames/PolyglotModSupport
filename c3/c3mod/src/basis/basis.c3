module basis;
import basis::bindings;

alias IntPtr = uptr;
alias IntPtr64 = ulong;
alias CppPtr = ulong;
alias WasmFuncPtr = uint;

macro printf(...)
{
	@pool()
	{
		String str = string::tformat(...$vaarg);
		InteropString is = { str, str.len };
		api::core_printOnHost(&is);
	}; // Temp allocator reset
}
