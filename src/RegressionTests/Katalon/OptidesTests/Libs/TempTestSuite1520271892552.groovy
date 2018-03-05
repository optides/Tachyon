import com.kms.katalon.core.logging.KeywordLogger
import com.kms.katalon.core.exception.StepFailedException
import com.kms.katalon.core.reporting.ReportUtil
import com.kms.katalon.core.main.TestCaseMain
import com.kms.katalon.core.testdata.TestDataColumn
import groovy.lang.MissingPropertyException
import com.kms.katalon.core.testcase.TestCaseBinding
import com.kms.katalon.core.driver.internal.DriverCleanerCollector
import com.kms.katalon.core.model.FailureHandling
import com.kms.katalon.core.configuration.RunConfiguration
import static com.kms.katalon.core.testcase.TestCaseFactory.findTestCase
import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject
import static com.kms.katalon.core.testdata.TestDataFactory.findTestData



def static runTestCase_0() {
    TestCaseMain.runTestCase('Test Cases/HT_DNA HTProduction Pipeline Test', new TestCaseBinding('Test Cases/HT_DNA HTProduction Pipeline Test',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_1() {
    TestCaseMain.runTestCase('Test Cases/HPLC Image Assay Pipeline', new TestCaseBinding('Test Cases/HPLC Image Assay Pipeline',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_2() {
    TestCaseMain.runTestCase('Test Cases/Insert Constructs via Pipeline Test', new TestCaseBinding('Test Cases/Insert Constructs via Pipeline Test',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_3() {
    TestCaseMain.runTestCase('Test Cases/Insert Variants via Pipeline Test', new TestCaseBinding('Test Cases/Insert Variants via Pipeline Test',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_4() {
    TestCaseMain.runTestCase('Test Cases/Insert Homologues via Pipeline Test', new TestCaseBinding('Test Cases/Insert Homologues via Pipeline Test',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_5() {
    TestCaseMain.runTestCase('Test Cases/Insert CHEMProducts via pipeline', new TestCaseBinding('Test Cases/Insert CHEMProducts via pipeline',  null), FailureHandling.STOP_ON_FAILURE)
    
}

def static runTestCase_6() {
    TestCaseMain.runTestCase('Test Cases/postTest-RemoveTestConstructs', new TestCaseBinding('Test Cases/postTest-RemoveTestConstructs',  null), FailureHandling.STOP_ON_FAILURE)
    
}


Map<String, String> suiteProperties = new HashMap<String, String>();


suiteProperties.put('id', 'Test Suites/OptidesLabkeyTests')

suiteProperties.put('name', 'OptidesLabkeyTests')

suiteProperties.put('description', '')
 

DriverCleanerCollector.getInstance().addDriverCleaner(new com.kms.katalon.core.webui.contribution.WebUiDriverCleaner())
DriverCleanerCollector.getInstance().addDriverCleaner(new com.kms.katalon.core.mobile.contribution.MobileDriverCleaner())



RunConfiguration.setExecutionSettingFile("C:\\Users\\Hector\\Documents\\HRInternetConsulting\\Clients\\FHCRC\\Tachyon\\src\\RegressionTests\\Katalon\\OptidesTests\\Reports\\OptidesLabkeyTests\\20180305_094452\\execution.properties")

TestCaseMain.beforeStart()

KeywordLogger.getInstance().startSuite('OptidesLabkeyTests', suiteProperties)

(0..6).each {
    "runTestCase_${it}"()
}

DriverCleanerCollector.getInstance().cleanDrivers()

KeywordLogger.getInstance().endSuite('OptidesLabkeyTests', null)