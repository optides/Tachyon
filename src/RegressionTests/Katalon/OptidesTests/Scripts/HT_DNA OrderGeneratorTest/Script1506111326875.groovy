import static com.kms.katalon.core.checkpoint.CheckpointFactory.findCheckpoint
import static com.kms.katalon.core.testcase.TestCaseFactory.findTestCase
import static com.kms.katalon.core.testdata.TestDataFactory.findTestData
import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject
import com.kms.katalon.core.checkpoint.Checkpoint as Checkpoint
import com.kms.katalon.core.checkpoint.CheckpointFactory as CheckpointFactory
import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as MobileBuiltInKeywords
import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile
import com.kms.katalon.core.model.FailureHandling as FailureHandling
import com.kms.katalon.core.testcase.TestCase as TestCase
import com.kms.katalon.core.testcase.TestCaseFactory as TestCaseFactory
import com.kms.katalon.core.testdata.TestData as TestData
import com.kms.katalon.core.testdata.TestDataFactory as TestDataFactory
import com.kms.katalon.core.testobject.ObjectRepository as ObjectRepository
import com.kms.katalon.core.testobject.TestObject as TestObject
import com.kms.katalon.core.webservice.keyword.WSBuiltInKeywords as WSBuiltInKeywords
import com.kms.katalon.core.webservice.keyword.WSBuiltInKeywords as WS
import com.kms.katalon.core.webui.keyword.WebUiBuiltInKeywords as WebUiBuiltInKeywords
import com.kms.katalon.core.webui.keyword.WebUiBuiltInKeywords as WebUI
import internal.GlobalVariable as GlobalVariable
import org.openqa.selenium.Keys as Keys

'use global script for log in with credentials and BASE_URL set there'
WebUI.callTestCase(findTestCase('OpenAndLogIn'), [:], FailureHandling.STOP_ON_FAILURE)

WebUI.mouseOver(findTestObject('Page_Start Page Optides/a_CompoundsRegistry'))

WebUI.waitForElementVisible(findTestObject('Page_Start Page Optides/a_Samples_CompReg'), 0)

WebUI.click(findTestObject('Page_Start Page Optides/a_Samples_CompReg'))

WebUI.click(findTestObject('Page_Assay Dashboard OptidesCompoun/a_Files'))

WebUI.click(findTestObject('Page_Assay Dashboard OptidesCompoun/span_ht_dna_generateOrder4Kata'))

WebUI.click(findTestObject('Page_Assay Dashboard OptidesCompoun/span_Import Data'))

WebUI.click(findTestObject('Page_Assay Dashboard OptidesCompoun/radioBtn_Upload HT Order Form'))

WebUI.click(findTestObject('Page_Assay Dashboard OptidesCompoun/button_Import'))

WebUI.setText(findTestObject('Page_Data Pipeline - CompoundsRegistry/input_Name'), 'TEST_HT_DNA_OrderGenerator 01')

WebUI.setText(findTestObject('Page_Upload a spreadsheet of orders/input_linker_seq_txt'), 'GS')

WebUI.selectOptionByValue(findTestObject('Page_Upload a spreadsheet of orders/select_vendor_name_lst'), 'GenScript', true)

WebUI.click(findTestObject('Page_Upload a spreadsheet of orders/span_Generate HT Order Form'))

pipelineStatus = WebUI.getAttribute(findTestObject('Page_Data Pipeline - CompoundsRegistry/a_PipelineStatus'), 'text')

System.out.println(pipelineStatus)

'Check every 10 seconds for a status update'
while ((pipelineStatus == 'ht_order_generator RUNNING') || (pipelineStatus == 'ht_order_generator WAITING')) {
    WebUI.delay(10)

    pipelineStatus = WebUI.getAttribute(findTestObject('Page_Data Pipeline - CompoundsRegistry/a_PipelineStatus'), 'text')
}

assert pipelineStatus == 'COMPLETE'

WebUI.closeBrowser()

