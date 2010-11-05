/**
 * Hyrule Validator
 * @accessors true
 */
component {

	property coldspring.beans.BeanFactory beanFactory;
	property IValidationMessageProvider validationMessageProvider;
	
	public Validator function init(String rb="DefaultValidatorMessages"){
		setValidationMessageProvider(new ValidatorMessage(arguments.rb));
		return this;
	}

	public ValidationResult function validate(required any dto,Struct dtoMD,ValidationResult vr,String context="*"){
		var validationResult = (isNUll(arguments.vr)) ?  new ValidationResult() : arguments.vr;	
		var dtoMetaData = (isNUll(arguments.dtoMD)) ?  getMetaData(arguments.dto) : arguments.dtoMD;
		
		//recurse down through the inheritence chain
		if( !isNull(dtoMetaData.extends) ) {	
			validate(arguments.dto, dtoMetaData.extends, validationResult);
		}

		var props = (isNULL(dtoMetaData.properties)) ? [] : dtoMetaData.properties;
		
		// for each property in the array
		for(var i=1; i <= arrayLen(props); ++i) {
			
			// the current property struct
			var prop = props[i];

			// we are only validating columns
			if( !structKeyExists(prop,"fieldtype") || prop.fieldtype == "column"){

				// the name of the current property
				var name = prop["name"];

				// the value of the property
				var val =  isNull(evaluate("arguments.dto." & "get#name#()")) ? "" : evaluate("arguments.dto." & "get#name#()");

				// add the value to the property map
				prop.value = val;

				// once we have checked null and empty we can do any other validations
				for(key in prop){
								
					var validator = '';
										
					switch(key){

						// we will deal with notnull later

						case "NOTEMPTY" : {
							validator = new rules.NotEmptyValidator();
							break;
						}
	
						case "MIN" : {
							validator  = new rules.MinValidator();
							break;
						}

						case "MAX" : {
							validator = new rules.MaxValidator();
							break;
						}

						case "RANGE" : {
							validator = new rules.RangeValidator();
							break;
						}

						case "SIZE" : {
							validator = new rules.SizeValidator();
							break;
						}

						case "INLIST" : {
							validator = new rules.InListValidator();
							break;
						}

						case "NOTINLIST" : {
							validator = new rules.NotInListValidator();
							break;
						}
						
						case "PAST" : {
							validator = new rules.PastValidator();
							break;
						}

						case "FUTURE" : {
							validator = new rules.FutureValidator();
							break;
						}

						case "ASSERTTRUE" : {
							validator = new rules.AssertTrueValidator();
							break;
						}
						case "ASSERTFALSE" : {
							validator = new rules.AssertFalseValidator();
							break;
						}

						case "UPPERCASE" : {
							validator = new rules.UpperCaseValidator();
							break;
						}

						case "LOWERCASE" : {
							validator = new rules.LowerCaseValidator();
							break;
						}

						case "PASSWORD" : {
							validator = new rules.PasswordValidator();
							break;
						}
						
						case "EMAIL" : {
							validator = new rules.EmailValidator();
							break;
						}

						case "CREDITCARD" : {
							validator = new rules.CreditCardNumberValidator();
							break;
						}

						case "SSN" : {
							validator = new rules.SSNValidator();
							break;
						}

						case "PHONE" : {
							validator = new rules.PhoneValidator();
							break;
						}

						case "ZIPCODE" : {
							validator = new rules.ZipCodeValidator();
							break;
						}

						case "DATE" : {
							validator = new rules.DateValidator();
							break;
						}

						case "ARRAY" : {
							validator = new rules.ArrayValidator();
							break;
						}

						case "STRUCT" : {
							validator = new rules.StructValidator();
							break;
						}

						case "BOOLEAN" : {
							validator = new rules.BooleanValidator();
							break;
						}

						case "QUERY" : {
							validator = new rules.QueryValidator();
							break;
						}

						case "URL" : {
							validator = new rules.URLValidator();
							break;
						}

						case "UUID" : {
							validator = new rules.UUIDValidator();
							break;
						}

						case "GUID" : {
							validator = new rules.GUIDValidator();
							break;
						}

						case "BINARY" : {
							validator = new rules.BinaryValidator();
							break;
						}

						case "NUMERIC" : {
							validator = new rules.NumericValidator();
							break;
						}

						case "STRING" : {
							validator = new rules.StringValidator();
							break;
						}

						case "VARIABLENAME" : {
							validator = new rules.VariableNameValidator();
							break;
						}

						case "ISMATCH" : {
							validator = new rules.IsMatchValidator();
							
							// if we find a {} in the is match property we are looking to match a value and not a string
							var propertyMatch = reMatchNoCase("({)([\w])+?(})",prop.isMatch);
							
							if( arrayLen(propertyMatch) ) {
								var property = reReplaceNoCase(propertyMatch[1],"({)([\w]+)(})","\2");
																
								for(var x=1; x<=arrayLen(props); x++){
									if( props[x].name == property && structKeyExists(props[x],"value") ){
										prop.compareto = props[x].value;
									}
								}
							} else {
								prop.compareto = prop.ismatch;
							}
							
							break;
						}

						case "CUSTOM" : {
							try {
								validator = createObject("component","#prop.custom#");
							} catch(any e) {
								throw(type="ValidatorError", message="Custom validation component #prop.custom# not found");
							}
							break;
						}
						
						case "CUSTOMLIST" : {
							for (var custom in listToArray(prop.customList)) {
								try {
									validator = createObject("component","#custom#");
									if( !validator.isValid(prop, arguments.context, arguments.dto) ) {					
										addErrorMessage(componentName=dtoMetaData.name, property=prop, validationResult=validationResult, validationType=custom);
									}
								} catch(any e) {
									throw(type="ValidatorError", message="Custom validation component #custom# not found");
								}
							}
							break;
						}
						
						case "COLDSPRINGBEAN" : {
							if (isNull(getBeanFactory())) {
								throw(type="ValidatorError", message="Coldspring Bean Factory is not injected in Validator");
							}
							validator = getBeanFactory().getBean(prop.coldspringBean);
							break;
						}
						
						case "COLDSPRINGBEANLIST" : {
							if (isNull(getBeanFactory())) {
								throw(type="ValidatorError", message="Coldspring Bean Factory is not injected in Validator");
							}
							for (var beanName in listToArray(prop.coldspringBeanList)) {
								validator = getBeanFactory().getBean(beanName);
								if( !validator.isValid(prop, arguments.context, arguments.dto) ) {					
									addErrorMessage(componentName=dtoMetaData.name, property=prop, validationResult=validationResult, validationType=beanName);
								}
							}
							break;
						}
						
					}//end switch(key)
					
					if ( right(key,4) != "LIST" && !isSimpleValue(validator)  && !validator.isValid(prop, arguments.context, arguments.dto) ) {
						var validationType = key;
						if ( key == "CUSTOM" || key == "COLDSPRINGBEAN" ) {
							validationType = prop[key];
						}
						addErrorMessage(componentName=dtoMetaData.name, property=prop, validationResult=validationResult, validationType=validationType);
					}		
				}

			}

		}
		
		return validationResult;
	}
	
	// PRIVATE
	
	private void function addErrorMessage(String componentName, Struct property, ValidationResult validationResult, String validationType) {
		var message = "";
		if (structKeyExists(arguments.property,"message")) {
			message = arguments.property.message;
		} else {
			message = getValidationMessageProvider().getMessageByType(arguments.validationType, arguments.property);
		}
		arguments.validationResult.addError(arguments.componentName, 'property', arguments.property.name, UCase(arguments.validationType), message);
	}
	
}
