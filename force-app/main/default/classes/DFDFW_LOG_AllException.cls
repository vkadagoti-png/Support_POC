/*
*********************************************************
Apex Class Name    : DFDFW_LOG_AllException
Created Date       : 8/22/2024
Author             : Cloud Synapps Inc.
Description        : Class used to create exception logs.
Test Class Name    : DFDFW_LOG_AllExceptionTest
*********************************************************
*/
public class DFDFW_LOG_AllException extends Exception {
    public String ModuleName {get; set;}
    public String StackTrace {get; set;}
    public String ClassName {get; set;}
    public String MethodName {get; set;}
    public String ExceptionCause {get; set;}
        
    public void log(Exception ex)
    {
     try
        {
            extractExceptionData(ex); 
            writeToObject(ex);
        }
        catch(Exception e)
        {new DFDFW_LOG_AllException().Module('DFDFW_LOG_AllException').log(e); }                 
    }
    
    public DFDFW_LOG_AllException Module(String Name)
    {
        ModuleName = name;
        return this;
    }
    
    public DFDFW_LOG_AllException ExceptionCause(String cause){ExceptionCause = cause; return this;}
    
    public void extractExceptionData(Exception ex)
    {
        try
        {
            stackTrace = ex.getStackTraceString()
                         .substringBefore('\n');
            
            className = stackTrace.substringAfter('.')
                        .substringBefore('.'); 
            
            methodName = stackTrace.substringBefore(':')
                         .substringAfter(className)
                         .substringAfter('.');    
        }
        catch(Exception e)
        {new DFDFW_LOG_AllException().Module('DFDFW_LOG_AllException').log(e); }                      
    }
    
    public void writeToObject(Exception ex)
    {
     try
        {
            Exception_Logger__c logger = new Exception_Logger__c();
            logger.Module_Name__c = ModuleName;
            logger.Stack_Trace__c = ex.getStackTraceString();
            logger.Class_Name__c = className;
            logger.Method_Name__c = methodName;
            logger.Line_Number__c = ex.getLineNumber();
            logger.Exception_Type__c = ex.getTypeName();
            logger.Exception_Cause_Override__c = ExceptionCause; 
            logger.Exception_Cause__c = String.valueOf(ex.getCause());
            
            logger.Exception_Message__c = ex.getMessage();
            
            insert logger;    
        }
        
        catch(Exception e)
        {new DFDFW_LOG_AllException().Module('DFDFW_LOG_AllException').log(e);}
        
    }
    
}