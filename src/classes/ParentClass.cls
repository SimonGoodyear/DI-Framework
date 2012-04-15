public class ParentClass implements IParentClass, IHasDependencies{

    public void doStuff(){
        system.debug('**** webAccess ' + webAccess);
    }
    
    private IHttp webAccess;
    
    private Map<string, object> dependancyMap;
    public Map<string, object> getDependencies(){
		dependancyMap = new Map<string, object>();    	
        
        dependancyMap.put(IHttp.class.toString(), null);
        return dependancyMap; 
    }
    
    public void gotDependencies(){

        webAccess = (IHttp)dependancyMap.get(IHttp.class.toString());
    
    }
    

}