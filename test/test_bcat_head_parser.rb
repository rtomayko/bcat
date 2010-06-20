require 'contest'
require 'bcat/html'

class HeadParserTest < Test::Unit::TestCase

  setup { @parser = Bcat::HeadParser.new }

  test 'starts in an unknown state' do
    assert @parser.html?.nil?
    assert @parser.buf.empty?
  end

  test 'detects non-HTML input' do
    @parser.feed("HOWDY <h1>")
    assert_equal false, @parser.html?
    assert_equal '', @parser.head
  end

  test 'separates head elements from body' do
    @parser.feed("<style>h1{ font-size:500% }</style>")
    @parser.feed("<h1>HOLLA</h1>")
    assert_equal "<style>h1{ font-size:500% }</style>", @parser.head.strip
    assert_equal "<body>\n<h1>HOLLA</h1>", @parser.body
  end

  test 'handles multiple head elements' do
    stuff = [
      "<style>h1{ font-size:500% }</style>",
      "<link rel=alternate>",
      "<script type='text/javascript'>{};</script>"
    ]
    stuff.each { |html| @parser.feed(html) }
    @parser.feed("\n        \n\n\n<h1>HOLLA</h1>")

    assert_equal stuff.join, @parser.head.strip
  end

  test 'handles full documents' do
    @parser.feed("<!DOCTYPE html>\n")
    @parser.feed("<html><head><title>YO</title></head>")
    @parser.feed("<body id=oyy><h1>OY</h1></body></html>")
    assert_equal "<title>YO</title>", @parser.head.strip
    assert_equal "<body id=oyy>\n<h1>OY</h1></body></html>", @parser.body
  end

  test 'knows when the head is fully parsed' do
    @parser.feed("<!DOCTYPE html>\n")
    assert !@parser.complete?

    @parser.feed("<html><head><title>YO</title></head>")
    assert !@parser.complete?

    @parser.feed("<body id=oyy><h1>OY</h1></body></html>")
    assert @parser.complete?
  end
end
