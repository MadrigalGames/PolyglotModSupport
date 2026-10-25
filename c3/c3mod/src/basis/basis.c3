module basis;
import basis::bindings;
import basis::global_data;

alias IntPtr = uptr;
alias IntPtr64 = ulong;
alias CppPtr = ulong;
alias WasmFuncPtr = uint;

LibraryGlobalData* g;

macro printf(...)
{
	@pool()
	{
		String str = string::tformat(...$vaarg);
		InteropString is = { str, str.len };
		api::core_printOnHost(&is);
	}; // Temp allocator reset
}
