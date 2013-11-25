TelluriumDriver
===============
Adds functionality to Selenium WebDriver. Especially useful for Javascript WebApps which require more advanced methods to wait until actions are executed. 

Usage
===============
Initialization
---------------
TelluriumDriver is meant to be incredibly user friendly. To initialize a new instance of tellurium just do

		t_driver = TelluriumDriver.new("browser_name","browser_version","hub_ip")

where you replace browser_name with chrome,firefox,or internet_explorer, browser_version with nil for chrome or firefox and 8,9,or 10 for internet_explorer, and hub_ip with the IP of the selenium grid hub you would like to use.

To use a local instance of tellurium driver, do:

       	       	t_driver = TelluriumDriver.new("browser_name","local")

Basic Calls
--------------
The most basic call of tellurium_driver is wait_and_click. It will wait for an element to appear, then click it. This is great for navigating a dynamic JS app. 

		t_driver = TelluriumDriver.new("browser_name","browser_version","hub_ip")
		t_driver.goto("http://myurl.com")

		t_driver.wait_and_click(:id,"clickable-button")
		t_driver.wait_and_click(:css,"#clickable-button")
		t_driver.wait_and_click(:name,"button")

tellurium_driver can also use Selenium WebDriver functions

		element = t_driver.find_element(:id,"clickable-button")
		element.click

To see all of the calls, check out tellurium_driver.rb. 
		    	       
