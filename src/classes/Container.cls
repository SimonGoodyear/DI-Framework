public class Container {

	private static Map<string, string> internalMap = new Map<string, string>();
	
	private static object getClass(String classNameAndCondition){
		List<string> parts = classNameAndCondition.split(';');
		return getClass(parts[0], (parts.size() > 1) ? parts[1] : null);		
	}

	public static object getClass(Type classType, String condition){
		return getClass(classType.toString().split('=')[1].replace(']',''), condition);
	}
		
	public static object getClass(String className, String condition){
		
		if(className.contains('='))
			className = className.split('=')[1].replace(']','');
			
		string key = className;
		string typeName;
		object ret;
		
		if(condition != null)
			key += ';' + condition;
			
		if(internalMap.containsKey(key)){
			typeName = internalMap.get(key);
		}
		else if(internalMap.containsKey(className)){
			typeName = internalMap.get(className);
		}
		
		if(typeName != null){
			ret = jsonInstantiate(typeName);
		} else{
			try{
				ret = jsonInstantiate(className);
			}catch(Exception ex){
				system.debug('****** something in here ' + ex);
			}
		}
		
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