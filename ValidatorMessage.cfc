/**
 * @displayname Validator Message
 * @hint I will load and retrieve default messages from the properties file passed in.
 * @accessors true
 * @output false
 */
component implements="IValidationMessageProvider" {

	property Struct messages;
	property String resourceBundle;
	
	public ValidatorMessage function init(required String rb){
		setResourceBundle(arguments.rb);
		setMessages(structNew());
		loadResourceBundle();
		return this;
	}
	
	public void function addMessage(required String type, required String message){
		var messages = getMessages();
		message[arguments.type] = arguments.message;
	}

	public String function getMessageByType(String type,Struct prop){
		var messages = getMessages();
		var errorMessage = "";
		var key = arguments.type;
		
		if (arguments.type == "custom") {
			key = arguments.prop.custom;
		}
		
		if (hasMessage(key)) {
			if(!structKeyExists(arguments.prop,"display")){
				prop.display = humanize(prop.name);
			}
			
			errorMessage = replaceTemplateText(messages[key],prop);
		}
		
		return errorMessage;
	}
	
	public Boolean function hasMessage(required String type){
		var messages = getMessages();
		return structKeyExists(messages, arguments.type);
	}
	
	private String function replaceTemplateText(String message,Struct prop){
		var templates = reMatchNoCase("({)([\w])+?(})",arguments.message);
		var m = arguments.message;
		
		if( arrayLen(templates) ) {
			// looop over the array, in each
			for(var i=1; i<=arrayLen(templates); ++i){
				var placeHolder = templates[i];
				var property = reReplaceNoCase(placeHolder,"({)([\w]+)(})","\2");
				// now we know the key we are looking for
				for(key in prop) {						
					if(uCase(key) == ucase(property)){
						m = replaceNoCase(m,placeHolder,prop[key],"all");
					}
				}
			}
		}

		return m;
	}	

	private void function loadResourceBundle(){
		var currentDirectory = getDirectoryFromPath(getCurrentTemplatePath());
		var defaultPath = currentDirectory & "resources/";
		var messages = {};
		var filePath = getResourceBundle();
		
		if (!findNoCase(".properties", filePath)) {
			filePath = filePath & ".properties";
		}
		if (!findNoCase("/", filePath)) {
			filePath = defaultPath & filePath;
		}
		
		if (!fileExists(filePath)) {
			throw(message="#filePath# not found");
		}
		var file = fileOpen(filePath);
	
	    while (!fileIsEOF(file)) {
	        var line = fileReadLine(file);
			var type = trim(listFirst(line,"="));
			var message = trim(listLast(line,"="));
			if (type!="") {
				messages[type] = message;
			}
	    }
		
		setMessages(messages);
	}

	public Struct function getDefaultErrorMessages(){
		return getMessages();
	}

	private String function humanize(String text){
		var loc = {};
		loc.returnValue = reReplace(arguments.text, "([[:upper:]])", " \1", "all"); 
		loc.returnValue = reReplace(loc.returnValue, "([[:upper:]]) ([[:upper:]]) ", "\1\2", "all"); 
		loc.returnValue = replace(loc.returnValue, "-", " ", "all"); 
		loc.returnValue = ucase(left(loc.returnValue,1)) & right(loc.returnValue,len(loc.returnValue)-1);	
		return loc.returnValue;		
	}
}