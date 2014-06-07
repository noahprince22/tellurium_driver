# TelluriumDriver

Adds functionality to Selenium WebDriver. Useful for Javascript WebApps which require more advanced methods to wait until actions are executed. 

Usage
===============
Initialization
---------------
TelluriumDriver is meant to be user friendly. To initialize a new instance of tellurium just do

		require 'tellurium_driver'
		require 'selenium-webdriver'

		driver = TelluriumDriver.new(browser: "browser_name")

To use a local instance of tellurium driver on chrome, do:

       	driver = TelluriumDriver.new(browser: "chrome")

To use a remote instance of IE10 on a hub located at url http://192.168.1.1:4444/wd/hub

		driver = TelluriumDriver.new(browser: "internet_explorer",
									version: 10,
									hub_url: "http://192.168.1.1:4444/wd/hub")

Basic Calls
--------------

There are several methods to navigate to a url.

		driver = TelluriumDriver.new(browser: "firefox")
		driver.go_to("http://myurl.com")

	 	driver.go_to_and_wait_to_load("http://myurl.com")

		driver.load_url_and_wait_for_element("http://myurl.com",:id,"password")

The most basic call of tellurium_driver is wait_and_click. It will wait for an element to appear, then click it. This is great for navigating a dynamic JS app. 
		
		driver.wait_and_click(:id,"clickable-button")
		driver.wait_and_click(:css,"#clickable-button")
		driver.wait_and_click(:name,"button")

Tellurium can use Selenium calls too.		

		element = driver.find_element(:id,"password")
		driver.wait_for_element_and_click(element)

To fill out forms:

   		driver.send_keys(:id,"first_name","Noah")
		driver.send_keys(:id,"last_name","Prince")
		driver.send_keys(:id,"email","noahprince8@gmail.com")

To fillout in one bunch, use form_fillout

   	    driver.form_fillout({"first_name"=>"Noah",
                           "last_name"=>"Prince",
                           "email"=>"noahprince8@gmail.com"})

To fillout selectors:

   		driver.click_selector(:id,"age","21")
		
To see all of the calls, check out the rdoc

# Contributing

Want to contribute?
=======


1. Fork it.
2. Create a branch (`git checkout -b my_change`)
3. Commit your changes (`git commit -am "Added new_method"`)
4. Push to the branch (`git push origin my_change`)
5. Open a Pull Request
