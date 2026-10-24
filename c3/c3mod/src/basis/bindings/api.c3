module basis::bindings::api;
import basis::bindings @public;

// Public wrappers over the generated function pointers, which are @private.
// Same role as bindings/api.zig in the Zig SDK.

fn void core_printOnHost(InteropString* str)
{
	basis::bindings::funcPtr_Core_printOnHost(str);
}

fn void componentContext_getName(InteropTypedPtr thisPtr, InteropString* str)
{
	basis::bindings::funcPtr_ComponentContext_getName(thisPtr, str);
}

fn void componentContext_getPosition(InteropTypedPtr thisPtr, InteropVec3* returnValue)
{
	basis::bindings::funcPtr_ComponentContext_getPosition(thisPtr, returnValue);
}

fn int componentContext_getPhysicsActor(InteropTypedPtr thisPtr, uptr* actorCppPtr, uint* actorType)
{
	return basis::bindings::funcPtr_ComponentContext_getPhysicsActor(thisPtr, actorCppPtr, actorType);
}

fn void physicsActor_addForce(uptr cppPtr, InteropVec3* force, InteropVec3* position, int wakeUp)
{
	basis::bindings::funcPtr_PhysicsActor_addForce(cppPtr, force, position, wakeUp);
}
