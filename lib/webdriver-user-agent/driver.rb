require 'json'
require 'selenium-webdriver'
require 'webdriver-user-agent/browser_options'
require 'webdriver-user-agent/devices'

module Webdriver
  module UserAgent
    class Driver
      include Singleton
      include Devices

      def for(opts)
        puts "opts are #{opts}"
        user_agent_string   = opts[:user_agent_string]
        user_agent_string ||= agent_string_for opts[:agent]
        options = BrowserOptions.new(opts, user_agent_string)
        build_driver_using options
      end

      private

      def resize_inner_window(driver, width, height)
        if driver.browser == :firefox or :chrome
          driver.execute_script("window.open(#{driver.current_url.to_json},'_blank');")
          driver.close
          driver.switch_to.window driver.window_handles.first
        end
        driver.execute_script("window.innerWidth = #{width}; window.innerHeight = #{height};")
      end

      def build_driver_using(options)
        puts "options are #{options.inspect} in build_driver_using"
        driver = Selenium::WebDriver.for options.browser, options.browser_options
        unless options.agent == :random
          resize_inner_window(driver, *resolution_for(options.agent, options.orientation, options.viewport_width, options.viewport_height))
        end
        driver
      end

    end
  end
end
