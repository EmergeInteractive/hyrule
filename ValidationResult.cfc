component accessors="true" hint="I hold the results of a call to the HyRule validator server validate function." {

	property Array errors;

	public ValidationResult function init(){
		setErrors([]);
		return this;
	}
	
	public Boolean function hasErrors() {
		return (arrayLen(getErrors()) > 0); 
	}
	
	public Array function getErrors(){
		return variables.errors;
	}
	
	public void function addError(required string class,required string validationLevel,required string property,required string validationType,required string message){
		var validationError = new ValidationError();
		
		validationError.setClass(arguments.class);
		validationError.setMessage(arguments.message);
		validationError.setProperty(arguments.property);
		validationError.setValidationLevel(arguments.validationLevel);
		validationError.setValidationType(arguments.validationType);
		
		arrayAppend(variables.errors,validationError);
	}

}
