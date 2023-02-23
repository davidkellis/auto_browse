require "ferrum"
# require "ferrum/browser/options/chrome"
require "capybara"
require "capybara/cuprite"

require_relative "capybara_ext"
require_relative "ferrum_ext"
require_relative "mouse"
require_relative "page"

module AutoBrowse
  class Browser
    def execute_script(javascript)
      raise "not implemented"
    end

    def goto(url)
      raise "not implemented"
    end

    def set_default_timeout(timeout = 30)
      raise "not implemented"
    end

    def quit
      raise "not implemented"
    end

    def driver
      raise "not implemented"
    end
  end


  class CupriteBrowser < Browser
    def self.set_global_default_timeout(timeout = 30)
      Capybara.default_max_wait_time = timeout
    end

    def self.register(extra_ferrum_options = {})
      Capybara.javascript_driver = :cuprite
      Capybara.register_driver(:cuprite) do |app|
        # the list of command line flags is enormous: https://peter.sh/experiments/chromium-command-line-switches/
        chrome_options = {
          # "hide-scrollbars" => nil,
          # "mute-audio" => nil,
          # "enable-automation" => nil,
          "disable-web-security" => nil,
          # "disable-session-crashed-bubble" => nil,
          "disable-breakpad" => nil,
          # "disable-sync" => nil,
          "no-first-run" => nil,
          "use-mock-keychain" => nil,
          # "keep-alive-for-test" => nil,
          # "disable-popup-blocking" => nil,
          # "disable-extensions" => nil,
          "disable-hang-monitor" => nil,
          "disable-features" => "site-per-process,TranslateUI",
          # "disable-translate" => nil,
          # "disable-background-networking" => nil,
          "enable-features" => "NetworkService,NetworkServiceInProcess",
          # "disable-background-timer-throttling" => nil,
          # "disable-backgrounding-occluded-windows" => nil,
          # "disable-client-side-phishing-detection" => nil,
          # "disable-default-apps" => nil,
          "disable-dev-shm-usage" => nil,
          # "disable-ipc-flooding-protection" => nil,
          # "disable-prompt-on-repost" => nil,
          # "disable-renderer-backgrounding" => nil,
          # "force-color-profile" => "srgb",
          "metrics-recording-only" => nil,
          # "safebrowsing-disable-auto-update" => nil,
          "password-store" => "basic"
        }
        chrome_options.merge!(headless: nil) if ENV["HEADLESS"] == "true"

        driver_options = {
          window_size: [1440, 900],
          # headless: ENV["HEADLESS"] == "true",    # has no effect
          ignore_default_browser_options: true,
          browser_options: chrome_options
        }.merge(extra_ferrum_options)

        Capybara::Cuprite::Driver.new(app, driver_options)
      end
    end

    def initialize
      @session = Capybara::Session.new(:cuprite)
      @windows = [@session.current_window]
    end

    def driver
      @session
    end

    def mouse
      @session.driver.browser.mouse
    end

    def move(x, y)
      mouse.move(x: x, y: y)
      sleep 0.01
    end

    def goto(url)
      @session.visit(url)
    end

    def visit(url)
      goto(url)
    end

    def new_window
      window = @session.open_new_window
      @windows << window
      window
    end

    def switch_to_window(window)
      @session.switch_to_window(window)
    end

    def windows
      @windows
    end

    def quit
      @session.quit
    end
  end

end
