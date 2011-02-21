require 'contest'
require 'bcat/browser'

class BrowserTest < Test::Unit::TestCase

  setup { @browser = Bcat::Browser.new('default', nil) }

  test 'shell quotes double-quotes, backticks, and parameter expansion' do
    assert_equal "\"http://example.com/\\\"/\\$(echo oops)/\\`echo howdy\\`\"",
      @browser.shell_quote("http://example.com/\"/$(echo oops)/`echo howdy`")
  end
end
