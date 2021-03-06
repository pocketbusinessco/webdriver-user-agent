require 'facets/hash/except'

module Webdriver
  module UserAgent

    MINIMUM_MACOS_VERSION_NUMBER = 12

    class BrowserOptions

      def initialize(opts, user_agent_string)
        @options = opts
        options[:browser] ||= :firefox
        options[:agent] ||= :iphone
        options[:orientation] ||= :portrait

        options[:viewport_width], options[:viewport_height] = parse_viewport_sizes(options[:viewport_width], options[:viewport_height])

        initialize_for_browser(user_agent_string)
      end

      def method_missing(*args, &block)
        m = args.first
        value = options[m]
        super unless value
        value.downcase
      end

      def browser_options
        options.except(:browser, :agent, :orientation, :user_agent_string, :viewport_width, :viewport_height)
      end

      private

      def options
        @options ||= {}
      end

      def initialize_for_browser(user_agent_string)
        case options[:browser]
        when :firefox
          options[:profile] ||= Selenium::WebDriver::Firefox::Profile.new
          options[:profile]['general.useragent.override'] = user_agent_string
        when :chrome
          options[:switches] ||= []
          options[:switches] << "--user-agent=#{user_agent_string}"
        when :safari
          change_safari_user_agent_string(user_agent_string)
          options
        else
          raise "WebDriver UserAgent currently only supports :chrome, :firefox and :safari."
        end
      end

      def parse_viewport_sizes(width, height)
        return ["0","0"] unless "#{width}".to_i > 0 && "#{height}".to_i > 0

        ["#{width}", "#{height}"]
      end

      def change_safari_user_agent_string(user_agent_string)
        raise "Safari requires a Mac" unless OS.mac?

        # Safari only works in technology preview, as of July 2017
        # https://github.com/SeleniumHQ/selenium/issues/2904#issuecomment-261736814
        Selenium::WebDriver::Safari.technology_preview!

        ua  = "\\\"#{user_agent_string}\\\"" # escape for shell quoting
        cmd = "defaults write com.apple.SafariTechnologyPreview CustomUserAgent \"#{ua}\""
        # Note that `com.apple.SafariTechnologyPreview` is the name specific
        # to the beta browser provided by Apple, which is required to use
        # Selenium with Safari, as of July 2017.
        # https://github.com/SeleniumHQ/selenium/issues/2904#issuecomment-261736814
        # If this changes, and this gem is changed to support using the
        # golden master Safari, the name of the configuration should be
        # changed to `com.apple.Safari`

        output = `#{cmd}`

        error_message  = "Unable to execute '#{cmd}'. "
        error_message += "Error message reported: '#{output}'"
        error_message += "Please execute the command manually and correct any errors."

        raise error_message unless $?.success?
      end

      # Require a Mac at version 12 (Sierra) or greater
      def require_mac_version
        raise "Safari requires a Mac" unless OS.mac?
        raise "Selenium only works with Safari on Sierra or newer" unless valid_mac_version?
      end

      def valid_mac_version?
        version = "#{`defaults read loginwindow SystemVersionStampAsString`}"
        version_number = "#{version.split(".")[1]}"
        version_number.to_i >= MINIMUM_MACOS_VERSION_NUMBER
      end

    end
  end
end
