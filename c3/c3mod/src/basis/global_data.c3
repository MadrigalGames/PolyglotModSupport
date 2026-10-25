module basis::global_data;
import basis;
import basis::components;

struct LibraryGlobalData
{
	// Global allocator. Only use it for global-data purposes.
	// If it is possible to pass an allocator to a function, prefer that.
	Allocator allocator;

	// When adding more global data here, if possible, name each field
	// after the module where it is used.
	components::GlobalData components;
}

// The data starts zeroed, so each module's GlobalData must be valid when zeroed
// or get an init() call here.
fn void create(Allocator allocator)
{
	basis::g = alloc::new(allocator, LibraryGlobalData);
	basis::g.allocator = allocator;
}

fn void destroy()
{
	alloc::free(basis::g.allocator, basis::g);
	basis::g = null;
}
