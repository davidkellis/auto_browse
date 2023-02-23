require "bundler"
Bundler.require

require "csv"
require "json"
require "pp"

require_relative "extlib"
require_relative "turbotax"

AutoBrowse::CupriteBrowser.set_global_default_timeout(10)
AutoBrowse::CupriteBrowser.register
browser = AutoBrowse::CupriteBrowser.new
tt = TurboTax.new(browser)

tt.instance_eval { self.page.select("Cryptocurrency", from: "What type of investment did you sell?", match: :first) }
tt.instance_eval { self.page.select("I purchased it", from: "How did you receive this investment?", match: :first) }
tt.instance_eval { self.page.fill_in("Description", with: "Sale on 1/15/2021") }
tt.instance_eval { self.page.fill_in("#stk-transaction-summary-entry-views-0-fields-5-choice-IsDateAcquiredALiteralInd-choices-0-choiceDetail-input-DateAcquiredDtPP", with: "01/12/2020") }
