# Provides added functionality to Selenium WebDriver
#
# Author:: Noah Prince (mailto:noahprince8@gmail.com)
class TelluriumDriver
  class << self
    attr_accessor :wait_for_document_ready
  end

  # :nodoc:
  def self.before(names)
    names.each do |name|
      m = instance_method(name)
      define_method(name) do |*args, &block|  
        yield
        m.bind(self).(*args, &block)
      end
    end
  end
  # :doc:
  
  # Sets up this instance of TelluriumDriver
  #
  # ==== Options
  #
  # * +:browser+ - "chrome","firefox", "safari" or "internet explorer"
  # * +:version+ - the version of the browser. Not needed for safari, chrome, or firefox
  # * +:hub_ip+ - the IP address of the Selenium Grid hub to test on. 
  #   * Will use http://hub_ip:4444/wd/hub. If this is not correct, use :hub_url
  # * +:hub_url+ - the full url address of the Selenium Grid hub to test on
  #   * WARNING: DO NOT USE BOTH hub_ip and hub_url
  #   * NOTE: If either hub_ip or hub_url is present, tests will not run locally
  # * +:caps+ - see https://code.google.com/p/selenium/wiki/DesiredCapabilities
  #   * Not necessary, but will give the browser any extra desired functionality
  # * +:timeout+ - Number of seconds for all Tellurium wait commands. Default 120
  #
  # ==== Examples
  #
  # Run a local chrome instance 
  #    TelluriumDriver.new(browser: "chrome") 
  #
  # Run an IE10 instance on the grid with ip 192.168.1.1
  #    TelluriumDriver.new(browser: "internet_explorer", version: 10, hub_ip: 192.168.1.1)
  def initialize(opts = {})
    opts[:timeout] = 120 unless opts[:timeout]
    @wait = Selenium::WebDriver::Wait.new(:timeout=>opts[:timeout])
    TelluriumDriver.wait_for_document_ready=true;

    opts[:caps] ||= {}
    opts[:caps][:browserName] ||= opts[:browser]
    opts[:caps][:version] ||= opts[:version]

    is_local = !opts[:hub_ip] and !opts[:hub_url]
    
    if is_local
      @driver = Selenium::WebDriver.for(opts[:browser].to_sym,:desired_capabilities=>opts[:caps])
    else
      @driver = Selenium::WebDriver.for(:remote,:desired_capabilities=>opts[:caps],:url=> "http://#{hub_ip}:4444/wd/hub")
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

  # Goes to a given url, does not wait for load
  #
  # ==== Attributes
  #
  # * +url+ - the url to visit
  def go_to(url)
    driver.get url
  end

  # Goes to a given url, waits for it to load
  #   * NOTE: To see if loaded, waits for the title of the window to change
  #
  # ==== Attributes
  #
  # * +url+ - the url to visit
  def go_to_and_wait_to_load(url)
    current_name = driver.title
    driver.get url

    # wait until the current title changes to see that you're at a new url
    @wait.until { driver.title != current_name }
  end

  # Goes to a given url, and waits for a given element to appear
  #
  # ==== Attributes
  #
  # * +url+ - the url to visit
  # * +sym+ - :id, :name, :css, etc
  # * +id+ - The text corresponding with the symbol.
  #
  # ==== Examples
  #     driver.load_url_and_wait_for_element(:id,"password")
  def load_url_and_wait_for_element(url,sym,id)
    current_name = driver.title
    driver.get url

    @wait.until { driver.title != current_name and driver.find_elements(sym, id).size > 0 }
  end

  # Waits for an element to be displayed on the page
  #
  # ==== Attributes
  #
  # * +element+ - Selenium::WebDriver::Element to appear
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

  # Waits for the element with specified identifiers to disappear 
  #
  # ==== Attributes
  #
  # * +sym+ - :id, :name, :css, etc
  # * +id+ - The text corresponding with the symbol.
  #
  # ==== Examples
  #
  #   driver.wait_to_disappear(:id,"hover-box")
  def wait_to_disappear(sym,id)
   @wait.until {
    element_arr = driver.find_elements(sym,id)
    element_arr.size > 0 and !element_arr[0].displayed? #wait until the element both exists and is displayed
  }
  end

  # Similar to wait_to_disappear, but takes an element instead of identifiers
  #   * WARNING: If the element disappears from the DOM, and isn't just hidden
  #              this will raise a stale reference error
  #
  # ==== Attributes
  #
  # * +element+ - Selenium::WebDriver::Element to appear
  #
  # ==== Examples
  #
  #    element = driver.find_element(id: "foo")
  #    driver.wait_for_element_to_disappear(element)
  def wait_for_element_to_disappear(element)
    @wait.until {
      begin
        !element.displayed?
      rescue
        break
      end
    }
  end

  # Waits for the element with specified identifiers to appear 
  #
  # ==== Attributes
  #
  # * +sym+ - :id, :name, :css, etc
  # * +id+ - The text corresponding with the symbol.
  #
  # ==== Examples
  #
  #    driver.wait_to_appear(:id,"hover-box")
  def wait_to_appear(sym,id)
   @wait.until {
    element_arr = driver.find_elements(sym,id)
    element_arr.size > 0 and element_arr[0].displayed? #wait until the element both exists and is displayed
   }
  end

  # Waits for the element with specified identifiers to appear, then clicks it 
  #
  # ==== Attributes
  #
  # * +sym+ - :id, :name, :css, etc
  # * +id+ - The text corresponding with the symbol.
  #
  # ==== Examples
  #
  #    driver.wait_and_click(:name,"hello")
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

  # Waits for the given element to appear and clicks it
  #
  # ==== Attributes
  #
  # * +element+ - Selenium::WebDriver::Element to appear
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

  # Clicks one element, and waits for the attribute of another element to change
  #   * NOTE: This method only takes ids
  #
  # ==== Attributes
  #
  # * +id_to_click+
  # * +id_to_change+
  # * +value+ - the attribute to change on the second element
  #
  # ==== Examples
  #
  #    driver.click_and_wait_to_change("checkbox","score","text")
  def click_and_wait_to_change(id_to_click,id_to_change,value) 
    element_to_click = driver.find_element(:id, id_to_click)
    element_to_change = driver.find_element(:id, id_to_change)
    current_value = element_to_change.attribute(value.to_sym)

    element_to_click.click
    @wait.until { element_to_change.attribute(value.to_sym) != current_value }
  end

  # Fills in a value for form selectors
  #
  # ==== Attributes
  #
  # * +sym+ - :id, :css, or :name, etc
  # * +id+ - The text corresponding with the symbol.
  # * +selector_value+ - The value to change the selector to
  #
  # ==== Examples
  #
  #    driver.click_selector(:id,"age","21")
  def click_selector(sym,id,selector_value)
    option = Selenium::WebDriver::Support::Select.new(driver.find_element(sym.to_sym,id))
    option.select_by(:text, selector_value)
  end

  # Fills in a value for form selectors and waits for another element to change
  #   * NOTE: This method only uses ids
  #
  # ==== Attributes
  #
  # * +id_to_click+
  # * +selector_value+ - The value to change the selector to
  # * +id_to_change+
  # * +value+ - the attribute to change on the second element
  #
  # ==== Examples
  #
  # Waits for the attribute "available" on the element with id: "drinks" to change
  # after filling an age selector to 21
  # 
  #    driver.click_selector_and_wait("age","21","drinks","available")
  def click_selector_and_wait(id_to_click,selector_value,id_to_change,value)
    element_to_change = driver.find_element(:id => id_to_change)
    current_value = element_to_change.attribute(value.to_sym)

    option = Selenium::WebDriver::Support::Select.new(driver.find_element(:id => id_to_click))
    option.select_by(:text, selector_value)
      
    @wait.until { element_to_change.attribute(value.to_sym) != current_value }
  end

  # Hovers over where an element should be and clicks. Useful for hitting hidden elements
  #
  # ==== Attributes
  #
  # * +element+ - Selenium::WebDriver::Element
  #
  # ===== OR
  #
  # * +sym+ - :id, :css, or :name, etc
  # * +id+ - The text corresponding with the symbol.
  def hover_click(*args)
    if args.size == 1
    driver.action.click(element).perform
    else
      sym,id = args
      driver.action.click(driver.find_element(sym.to_sym,id)).perform
    end

  end

  # Fills a text input of the given sym,id with a value
  # 
  # ==== Attributes
  #
  # * +sym+ - :id, :css, or :name, etc
  # * +id+ - The text corresponding with the symbol.
  # * +value+ - the string to send to the text input
  def send_keys(sym,id,value)
    #self.wait_and_click(sym, id)
    #driver.action.send_keys(driver.find_element(sym => id),value).perform
    wait_to_appear(sym,id)
    element = driver.find_element(sym,id)
    element.click
    element.send_keys(value)
  end

  # :nodoc:
  def send_keys_leasing(sym,id,value)
    self.wait_to_appear(sym,id)
    self.driver.find_element(sym,id).send_keys(value) 
  end
  # :doc:

  # Clicks one element and waits for another to exist
  #
  # ==== Attributes
  #
  # * +id1+ - Id of element to click
  # * +id2+ - Id of element to exist
  #
  # ===== OR
  #
  # * +sym1+ - :id, :css, or :name, etc for the element to click
  # * +id1+ - The text corresponding with the symbol. 
  # * +sym2+ - :id, :css, or :name, etc for the element to wait to exist
  # * +id2+ - The text corresponding with the symbol. 
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

  # Fills out large forms via a supplied hash in the form id,value_to_send
  #
  # ==== Attributes
  #
  # * +hash+ - A hash of input IDs associated with the value to send to the input
  #
  # ==== Examples
  #
  # Fill out a login form
  #    driver.form_fillout({"first_name"=>"Noah",
  #                         "last_name"=>"Prince",
  #                         "email"=>"noahprince8@gmail.com"})
  def form_fillout(hash)
    hash.each do |id,value|
      self.wait_to_appear(:id,id)
       self.send_keys(:id,id,value)
    end

  end

  # :nodoc:
  def form_fillout_editable(selector,hash)
    hash.each do |id,value|
      name = "#{selector}\[#{id}\]"
      driver.execute_script("$('[data-field=\"#{name}\"]').editable('setValue', '#{value}');")
    end
  end
  # :doc:

  # Fills out large numbers of selectors via a supplied hash in the form id,value_to_send
  #
  # ==== Attributes
  #
  # * +hash+ - A hash of input IDs associated with the value to send to the input
  #
  # ==== Examples
  #
  # Fill out a login form
  #    driver.form_fillout({"age"=>"21","num_of_pets"=>"2","num_of_stars"=>"5"})
  def form_fillout_selector(hash)
    hash.each do |id,value|
      option = Selenium::WebDriver::Support::Select.new(driver.find_element(:id => id))
      option.select_by(:text,value)
    end

  end

  # Waits for the element specified by the identifiers then clicks where it should be
  #
  # ==== Attributes
  # 
  # * +sym+ - :id, :css, or :name, etc
  # * +id+ - The text corresponding with the symbol.
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

  # Closes the webdriver
  def close
    driver.quit
  end

  def document_ready

  end

end 
