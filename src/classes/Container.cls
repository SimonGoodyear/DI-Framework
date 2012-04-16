public class Container {

	private static Map<string, string> internalMap = new Map<string, string>();
	
	private static object getClass(String classNameAndCondition){
		List<string> parts = classNameAndCondition.split(';');
		return getClass(parts[0], (parts.size() > 1) ? parts[1] : null);		
	}

	public static object getClass(Type classType, String condition){
		return getClass(classType.toString().split('=')[1].replace(']',''), condition);
	}
		
	public static object getClass(String interfaceName, String condition){
		
		// If the user passed Interface.class.toString() we need to
		// split out the interface name from the stringifyed type class		
		if(interfaceName.contains('='))
			interfaceName = interfaceName.split('=')[1].replace(']','');
			
		string key = interfaceName;
		string typeName;
		object ret;
		
		// Build the key into the map
		if(condition != null)
			key += ';' + condition;
			
		// Get the name of the concrete class we need
		if(internalMap.containsKey(key)){
			typeName = internalMap.get(key);
		}
		else if(internalMap.containsKey(interfaceName)){
			typeName = internalMap.get(interfaceName);
		}
		
		// Try and instantiate the class we picked from the map
		// If there wasn't anything in the map try and instatiate
		// the vaule passed in as the required interface as someone 
		// may have passed a class name		
		if(typeName != null){
			ret = jsonInstantiate(typeName);
		} else{
			try{
				ret = jsonInstantiate(interfaceName);
			}catch(Exception ex){
				system.debug('****** something in here ' + ex);
			}
		}
		
		// Check to see if the new class needs any dependencies filling in
		if(ret != null && ret instanceof IHasDependencies){
			Map<string, object> deps = ((IHasDependencies)ret).getDependencies();
			Map<string, object> newDeps = new Map<string, object>();
			for(string s : deps.keySet()){
				newDeps.put(s, Container.getClass(s));
			}
			
			deps.clear();
			deps.putAll(newDeps);
			
			((IHasDependencies)ret).gotDependencies();
		}
		
		return ret;
	}
	
	private static object jsonInstantiate(string typeName){
		JSONParser parser = JSON.createParser('{}');
		return parser.readValueAs(Type.forName(typeName));		
	}
	
	public static void addMapping(ClassMap mapping){
		if(mapping == null)
			return;
			
		string theClass = mapping.theClass.toString().split('=')[1].replace(']','');
		string theInterface = mapping.theInterface.toString().split('=')[1].replace(']','') + (mapping.condition != null ? ';' + mapping.condition : '');
		if(!internalMap.containsKey(theInterface))
			internalMap.put(theInterface, theClass);
	}
	
	public static void loadMappingFile(string fileName){
		List<StaticResource> resources = [SELECT Id, Body FROM StaticResource WHERE Name = :fileName];
		if(resources == null || resources.size() == 0)
			return;
			
		if(resources.size() > 1)
			return; // Should probably throw an exception here - non specific resource
			
		List<Container.ClassMapFileEntry> mappings = (List<Container.ClassMapFileEntry>)JSON.deserialize(resources[0].body.toString(), List<Container.ClassMapFileEntry>.class);
		for(ClassMapFileEntry mapping : mappings)
			Container.addMapping(new ClassMap(mapping));
	}
	
	public class ClassMap{
		public ClassMap(){}
		
		public ClassMap(ClassMapFileEntry fileEntry){
			theInterface = Type.forName(fileEntry.theInterface);
			theClass = Type.forName(fileEntry.theClass);
		}
		public Type theInterface {get; set;}
		public Type theClass {get; set;}
		public string condition {get; set;}
	}
	
	private class ClassMapFileEntry{
		public string theInterface {get; set;}
		public string theClass {get; set;}
		public string condition {get; set;}
		
	}
}