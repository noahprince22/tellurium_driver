#Provides added functionality to Selenium WebDriver
class TelluriumDriver
  class << self
    attr_accessor :wait_for_document_ready
  end
  
  #takes browser name, browser version, hub ip(optional) 
  def self.before(names)
    names.each do |name|
      m = instance_method(name)
      define_method(name) do |*args, &block|  
        yield
        m.bind(self).(*args, &block)
      end
    end
  end
  
  #@sets up this instance of TelluriumDriver
  #@param [String] browser, "chrome","firefox", or "internet explorer"
  #@param [Integer] version, the version of the browser. nil for firefox or chrome, or "local" to run locally
  #@param hub_ip [String] the IP address of the Selenium Grid hub to test on
  #@param [Integer] timeout, the timeout to use on test
  def initialize(*args)
    browser, version,hub_ip,timeout = args
    timeout = 120 unless timeout
    @wait = Selenium::WebDriver::Wait.new(:timeout=>timeout)
    TelluriumDriver.wait_for_document_ready=true;
    
    is_local = version.include?("local") if version and version.is_a? String
    is_ie = browser.include?("internet") && version
    is_chrome = browser.include?("chrome")
    is_firefox = browser.include?("firefox") 

    if is_chrome && is_local
      caps = {
        :browserName => "chrome",
        :idleTimeout => timeout
        # :screenshot => true
      }
      @driver = Selenium::WebDriver.for :chrome,:desired_capabilities=>caps
    elsif is_firefox && is_local
      caps = {
        :browserName => "firefox",
        :idleTimeout => timeout,
        :screenshot => true
      }
      @driver = Selenium::WebDriver.for :firefox, :desired_capabilities=>caps
    elsif is_ie
      caps = Selenium::WebDriver::Remote::Capabilities.internet_explorer
      caps.version = version.to_s
      @driver = Selenium::WebDriver.for(:remote,:desired_capabilities=>caps,:url=> "http://#{hub_ip}:4444/wd/hub")
    elsif is_chrome
      @driver = Selenium::WebDriver.for(:remote,:desired_capabilities=>:chrome,:url=> "http://#{hub_ip}:4444/wd/hub")
    elsif is_firefox
      @driver = Selenium::WebDriver.for(:remote,:desired_capabilities=>:firefox,:url=> "http://#{hub_ip}:4444/wd/hub")
    end

  end


  TelluriumDriver.before(TelluriumDriver.instance_methods.reject { |name| name.to_s.include?("initialize")}) do
    begin
      if(TelluriumDriver.wait_for_document_ready)
        wait = Selenium::WebDriver::Wait.new(:timeout=>120)
        wait.until{ self.driver.execute_script("document.readyState") == "complete" }
      end
    rescue Exception => e
      puts e.message
    end
  end

  def driver
    @driver
  end


  def method_missing(sym, *args, &block)
    @driver.send sym,*args,&block
  end

  #@param [String] url, the url to point the driver at
  def go_to(url)
    driver.get url
  end

  #Waits for the title to change after going to a url
  #@param [String] url, the url to go to
  def go_to_and_wait_to_load(url)
    current_name = driver.title
    driver.get url

    #wait until the current title changes to see that you're at a new url
    @wait.until { driver.title != current_name }
  end
  
  #takes a url, the symbol of what you wait to exist and the id/name/xpath, whatever of what you want to wait to exist
  def load_website_and_wait_for_element(url,arg1,id)
    current_name = driver.title
    driver.get url

    @wait.until { driver.title != current_name and driver.find_elements(arg1, id).size > 0 }
  end
  
  #clicks one element and waits for another one to change it's value. 
  #@param [String] id_to_click, the id you want to click
  #@param [String] id_to_change you
  def click_and_wait_to_change(id_to_click,id_to_change,value) 
    element_to_click = driver.find_element(:id, id_to_click)
    element_to_change = driver.find_element(:id, id_to_change)
    current_value = element_to_change.attribute(value.to_sym)

    element_to_click.click
    @wait.until { element_to_change.attribute(value.to_sym) != current_value }
  end

  #Fills in a value for form selectors
  #@param [Symbol] sym, usually :id, :css, or :name
  #@param [String] selector_value, the value to set the selector to
  def click_selector(sym,id,selector_value)
    option = Selenium::WebDriver::Support::Select.new(driver.find_element(sym.to_sym,id))
    option.select_by(:text, selector_value)
  end

  #Fills out a selector and waits for another id to change
  def click_selector_and_wait(id_to_click,selector_value,id_to_change,value)
    element_to_change = driver.find_element(:id => id_to_change)
    current_value = element_to_change.attribute(value.to_sym)

    option = Selenium::WebDriver::Support::Select.new(driver.find_element(:id => id_to_click))
    option.select_by(:text, selector_value)
      
    @wait.until { element_to_change.attribute(value.to_sym) != current_value }
  end

  #Waits for an element to be displayed
  #@param [SeleniumWebdriver::Element]
  def wait_for_element(element)
      @wait.until {
          bool = false

           if(element.displayed?)
              bool = true
              @element = element
              break
           end       

         bool == true
      }
  end

  #Waits for the element with specified identifiers to disappear
  #@param [Symbol] sym
  #@param [String] id
  def wait_to_disappear(sym,id)
   @wait.until {
    element_arr = driver.find_elements(sym,id)
    element_arr.size > 0 and !element_arr[0].displayed? #wait until the element both exists and is displayed
  }
  end

  #waits for an element to disappear
  #@param [SeleniumWebdriver::Element] element
  def wait_for_element_to_disappear(element)
    @wait.until {
      begin
        !element.displayed?
      rescue
        break
      end
    }
  end

  #@param [Symbol] sym
  #@param [String] id, the string associated with the symbol to identify the elementw
  def wait_to_appear(sym,id)
   @wait.until {
    element_arr = driver.find_elements(sym,id)
    element_arr.size > 0 and element_arr[0].displayed? #wait until the element both exists and is displayed
   }
  end

  # to change. (Example, I click start-application and wait for the next dialogue
  # box to not be hidden)
  def wait_and_click(sym, id)
   found_element = false

    #if the specified symbol and id point to multiple elements, we want to find the first visible one
    #and click that
    @wait.until do
      driver.find_elements(sym,id).shuffle.each do |element|
        if element.displayed? and element.enabled?
          @element=element
          found_element = true
        end 
      
      end
     found_element   
    end

    i = 0

    begin
      @element.click
    rescue Exception => ex
      i+=1
      sleep(1)
      retry if i<20
      raise ex 
    end
    
  end

  # Waits for an element to be displayed and click it
  #@param [SeleniumWebdriver::Element] 
  def wait_for_element_and_click(element)
    wait_for_element(element)
    
    i = 0
    begin
      @element.click
    rescue Exception => ex
      i+=1
      sleep(1)
      retry if i<20
      raise ex 
    end
    
  end

  #hovers where the element is and clicks. Workaround for timeout on click that happened with the new update to the showings app
  #@param [SeleniumWebdriver::Element] element OR can take sym,id
  def hover_click(*args)
    if args.size == 1
    driver.action.click(element).perform
    else
      sym,id = args
      driver.action.click(driver.find_element(sym.to_sym,id)).perform
    end

  end

  #fills an input of the given sym,id with a value
  #@param [Symbol] sym
  #@param [String] id
  #@param [String] value
  def send_keys(sym,id,value)
    #self.wait_and_click(sym, id)
    #driver.action.send_keys(driver.find_element(sym => id),value).perform
    wait_to_appear(sym,id)
    element = driver.find_element(sym,id)
    element.click
    element.send_keys(value)
  end

  def send_keys_leasing(sym,id,value)
    self.wait_to_appear(sym,id)
    self.driver.find_element(sym,id).send_keys(value) 
  end

  #takes the id you want to click, the id you want to exist.(Example, I click start-application and wait for the next dialogue box to exist
  def click_and_wait_to_exist(*args) 
     case args.size
     when 2 #takes just two id's
       id1,id2 = args
        element_to_click = driver.find_element(:id => id1)
        element_to_change = driver.find_element(:id => id2)

        element_to_click.click
        wait_for_element(element_to_change)

     when 4 #takes sym,sym2,id1,id2
       sym,sym2,id1,id2 = args
        element_to_click = driver.find_element(sym => id)
        element_to_change = driver.find_element(sym2 => id2)

        element_to_click.click
        wait_for_element(element_to_change)

     else
        error
     end
  end
  
  def form_fillout(hash) #takes a hash of ID's with values to fillout
    hash.each do |id,value|
      self.wait_to_appear(:id,id)
       self.send_keys(:id,id,value)
    end

  end
  
  def form_fillout_editable(selector,hash)
    hash.each do |id,value|
      name = "#{selector}\[#{id}\]"
      driver.execute_script("$('[data-field=\"#{name}\"]').editable('setValue', '#{value}');")
    end
  end
  
  def form_fillout_selector(hash)
    hash.each do |id,value|
      option = Selenium::WebDriver::Support::Select.new(driver.find_element(:id => id))
      option.select_by(:text,value)
    end

  end
  
  def wait_and_hover_click(sym,id)
    found = false
  #wait until an element with sym,id is displayed. When it is, hover click it
    @wait.until {
      elements = driver.find_elements(sym, id)
      elements.each do |element| 
        if element.displayed?
          found = true
          @element = element
        end
    
       end
      found == true
    } 
    self.hover_click(@element)
  end

  def close
    driver.quit
  end

  def document_ready

  end

end 
