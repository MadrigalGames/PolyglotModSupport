module basis::component_factory;
import basis;
import basis::bindings;
import std::collections::list;

alias DeinitFn = fn void(ComponentFactoryInterface* self);
alias NewComponentFn = fn IntPtr(ComponentFactoryInterface* self, InteropTypedPtr cppContextPtr, bool onClient);
alias DeleteComponentFn = fn void(ComponentFactoryInterface* self, bool onClient, IntPtr componentIntPtr);
alias UpdateFn = fn void(ComponentFactoryInterface* self, bool onClient, float deltaTime);
alias ComponentFn = fn void(ComponentFactoryInterface* self, IntPtr componentIntPtr);
alias DrawEditorFn = fn void(ComponentFactoryInterface* self, IntPtr componentIntPtr, bool selected, bool hoveredOver);

struct VirtualTable
{
	DeinitFn deinit;
	NewComponentFn newComponent;
	DeleteComponentFn deleteComponent;
	UpdateFn update;
	UpdateFn preTick;
	UpdateFn tick;

	// Methods forwarded to individual components:
	ComponentFn create;
	ComponentFn onObjectCreated;
	DrawEditorFn drawEditor;
}

struct ComponentFactoryInterface
{
	IntPtr object;
	VirtualTable* vTable;
	sz typeIndex;
}

fn void ComponentFactoryInterface.deinit(&self)
{
	self.vTable.deinit(self);
}

fn IntPtr ComponentFactoryInterface.newComponent(&self, InteropTypedPtr cppContextPtr, bool onClient)
{
	return self.vTable.newComponent(self, cppContextPtr, onClient);
}

fn void ComponentFactoryInterface.deleteComponent(&self, bool onClient, IntPtr componentIntPtr)
{
	self.vTable.deleteComponent(self, onClient, componentIntPtr);
}

fn void ComponentFactoryInterface.update(&self, bool onClient, float deltaTime)
{
	self.vTable.update(self, onClient, deltaTime);
}

fn void ComponentFactoryInterface.preTick(&self, bool onClient, float tickDeltaTime)
{
	self.vTable.preTick(self, onClient, tickDeltaTime);
}

fn void ComponentFactoryInterface.tick(&self, bool onClient, float tickDeltaTime)
{
	self.vTable.tick(self, onClient, tickDeltaTime);
}

fn void ComponentFactoryInterface.create(&self, IntPtr componentIntPtr)
{
	self.vTable.create(self, componentIntPtr);
}

fn void ComponentFactoryInterface.onObjectCreated(&self, IntPtr componentIntPtr)
{
	self.vTable.onObjectCreated(self, componentIntPtr);
}

fn void ComponentFactoryInterface.drawEditor(&self, IntPtr componentIntPtr, bool selected, bool hoveredOver)
{
	self.vTable.drawEditor(self, componentIntPtr, selected, hoveredOver);
}

//----------------------------------------------------

fn void setupVTable(ComponentFactoryInterface* iface, VirtualTable* vTable) <FactoryType>
{
	vTable.deinit = &wrapDeinit{FactoryType};
	vTable.newComponent = &wrapNewComponent{FactoryType};
	vTable.deleteComponent = &wrapDeleteComponent{FactoryType};
	vTable.update = &wrapUpdate{FactoryType};
	vTable.preTick = &wrapPreTick{FactoryType};
	vTable.tick = &wrapTick{FactoryType};
	vTable.create = &wrapCreate{FactoryType};
	vTable.onObjectCreated = &wrapOnObjectCreated{FactoryType};
	vTable.drawEditor = &wrapDrawEditor{FactoryType};

	iface.vTable = vTable;
}

fn void wrapDeinit(ComponentFactoryInterface* self) <FactoryType>
{
	((FactoryType*)self.object).deinit();
}

fn IntPtr wrapNewComponent(ComponentFactoryInterface* self, InteropTypedPtr cppContextPtr, bool onClient) <FactoryType>
{
	return ((FactoryType*)self.object).newComponent(cppContextPtr, onClient);
}

fn void wrapDeleteComponent(ComponentFactoryInterface* self, bool onClient, IntPtr componentIntPtr) <FactoryType>
{
	((FactoryType*)self.object).deleteComponent(onClient, componentIntPtr);
}

fn void wrapUpdate(ComponentFactoryInterface* self, bool onClient, float deltaTime) <FactoryType>
{
	((FactoryType*)self.object).update(onClient, deltaTime);
}

fn void wrapPreTick(ComponentFactoryInterface* self, bool onClient, float tickDeltaTime) <FactoryType>
{
	((FactoryType*)self.object).preTick(onClient, tickDeltaTime);
}

fn void wrapTick(ComponentFactoryInterface* self, bool onClient, float tickDeltaTime) <FactoryType>
{
	((FactoryType*)self.object).tick(onClient, tickDeltaTime);
}

fn void wrapCreate(ComponentFactoryInterface* self, IntPtr componentIntPtr) <FactoryType>
{
	((FactoryType*)self.object).create(componentIntPtr);
}

fn void wrapOnObjectCreated(ComponentFactoryInterface* self, IntPtr componentIntPtr) <FactoryType>
{
	((FactoryType*)self.object).onObjectCreated(componentIntPtr);
}

fn void wrapDrawEditor(ComponentFactoryInterface* self, IntPtr componentIntPtr, bool selected, bool hoveredOver) <FactoryType>
{
	((FactoryType*)self.object).drawEditor(componentIntPtr, selected, hoveredOver);
}

//----------------------------------------------------

struct GameObjectComponentFactory <ComponentType>
{
	ComponentFactoryInterface iface;
	VirtualTable vTable;
	List{ ComponentType* } clientComponents;
	List{ ComponentType* } serverComponents;
}

fn void GameObjectComponentFactory.init(&self, sz typeIndex)
{
	self.iface.object = (IntPtr)self;
	self.iface.typeIndex = typeIndex;
	setupVTable{GameObjectComponentFactory{ComponentType}}(&self.iface, &self.vTable);

	self.clientComponents.init(mem);
	self.serverComponents.init(mem);
}

fn void GameObjectComponentFactory.deinit(&self)
{
	self.clientComponents.free();
	self.serverComponents.free();

	// Release the memory for the factory itself.
	free(self);
}

fn IntPtr GameObjectComponentFactory.newComponent(&self, InteropTypedPtr cppContextPtr, bool onClient)
{
	// Allocate the component on the heap.
	ComponentType* componentPtr = mem::new(ComponentType);

	componentPtr.init(cppContextPtr, onClient);

	if (onClient)
	{
		self.clientComponents.push(componentPtr);
	}
	else
	{
		self.serverComponents.push(componentPtr);
	}

	return (IntPtr)componentPtr;
}

fn void GameObjectComponentFactory.deleteComponent(&self, bool onClient, IntPtr componentIntPtr)
{
	ComponentType* componentPtr = (ComponentType*)componentIntPtr;

	$if $defined(ComponentType.destroy):
		componentPtr.destroy();
	$endif

	// Remove the component ptr from the correct list.
	if (onClient)
	{
		foreach (i, compPtr : self.clientComponents)
		{
			if (compPtr == componentPtr)
			{
				self.clientComponents.remove_at(i);
				break;
			}
		}
	}
	else
	{
		foreach (i, compPtr : self.serverComponents)
		{
			if (compPtr == componentPtr)
			{
				self.serverComponents.remove_at(i);
				break;
			}
		}
	}

	free(componentPtr);
}

fn void GameObjectComponentFactory.update(&self, bool onClient, float deltaTime)
{
	$if $defined(ComponentType.update):
		if (onClient)
		{
			foreach (comp : self.clientComponents)
			{
				comp.update(deltaTime);
			}
		}
		else
		{
			foreach (comp : self.serverComponents)
			{
				comp.update(deltaTime);
			}
		}
	$endif
}

fn void GameObjectComponentFactory.preTick(&self, bool onClient, float tickDeltaTime)
{
	$if $defined(ComponentType.preTick):
		if (onClient)
		{
			foreach (comp : self.clientComponents)
			{
				comp.preTick(tickDeltaTime);
			}
		}
		else
		{
			foreach (comp : self.serverComponents)
			{
				comp.preTick(tickDeltaTime);
			}
		}
	$endif
}

fn void GameObjectComponentFactory.tick(&self, bool onClient, float tickDeltaTime)
{
	$if $defined(ComponentType.tick):
		if (onClient)
		{
			foreach (comp : self.clientComponents)
			{
				comp.tick(tickDeltaTime);
			}
		}
		else
		{
			foreach (comp : self.serverComponents)
			{
				comp.tick(tickDeltaTime);
			}
		}
	$endif
}

fn void GameObjectComponentFactory.create(&self, IntPtr componentIntPtr)
{
	$if $defined(ComponentType.create):
		ComponentType* comp = (ComponentType*)componentIntPtr;
		comp.create();
	$endif
}

fn void GameObjectComponentFactory.onObjectCreated(&self, IntPtr componentIntPtr)
{
	$if $defined(ComponentType.onObjectCreated):
		ComponentType* comp = (ComponentType*)componentIntPtr;
		comp.onObjectCreated();
	$endif
}

fn void GameObjectComponentFactory.drawEditor(&self, IntPtr componentIntPtr, bool selected, bool hoveredOver)
{
	$if $defined(ComponentType.drawEditor):
		ComponentType* comp = (ComponentType*)componentIntPtr;
		comp.drawEditor(selected, hoveredOver);
	$endif
}
