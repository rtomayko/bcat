require 'contest'
require 'bcat/ansi'

class ANSITest < Test::Unit::TestCase
  test 'should not modify input string' do
    text = "some text"
    Bcat::ANSI.new(text).to_html
    assert_equal "some text", text
  end

  test 'passing through text with no escapes' do
    text = "hello\nthis is bcat\n"
    ansi = Bcat::ANSI.new(text)
    assert_equal text, ansi.to_html
  end

  test "removing backspace characters" do
    text = "like this"
    ansi = Bcat::ANSI.new(text)
    assert_equal "like this", ansi.to_html
  end

  test "foreground colors" do
    text = "colors: \x1b[30mblack\x1b[37mwhite"
    expect = "colors: " +
      "<span style='color:#000'>black" +
      "<span style='color:#AAA'>white" +
      "</span></span>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "background colors" do
    text = "colors: \x1b[40mblack\x1b[47mwhite"
    expect = "colors: " +
      "<span style='background-color:#000'>black" +
      "<span style='background-color:#AAA'>white" +
      "</span></span>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "strikethrough" do
    text = "strike: \x1b[9mthat"
    expect = "strike: <strike>that</strike>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "blink!" do
    text = "blink: \x1b[5mwhat"
    expect = "blink: <blink>what</blink>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "underline" do
    text = "underline: \x1b[3mstuff"
    expect = "underline: <u>stuff</u>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "bold" do
    text = "bold: \x1b[1mstuff"
    expect = "bold: <b>stuff</b>"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "resetting a single sequence" do
    text = "\x1b[1mthis is bold\x1b[0m, but this isn't"
    expect = "<b>this is bold</b>, but this isn't"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "resetting many sequences" do
    text = "normal, \x1b[1mbold, \x1b[3munderline, \x1b[31mred\x1b[0m, normal"
    expect = "normal, <b>bold, <u>underline, " +
      "<span style='color:#A00'>red</span></u></b>, normal"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "multi-attribute sequences" do
    text = "normal, \x1b[1;3;31mbold, underline, and red\x1b[0m, normal"
    expect = "normal, <b><u><span style='color:#A00'>" +
      "bold, underline, and red</span></u></b>, normal"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "multi-attribute sequences with a trailing semi-colon" do
    text = "normal, \x1b[1;3;31;mbold, underline, and red\x1b[0m, normal"
    expect = "normal, <b><u><span style='color:#A00'>" +
      "bold, underline, and red</span></u></b>, normal"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end

  test "eating malformed sequences" do
    text = "\x1b[25oops forgot the 'm'"
    expect = "oops forgot the 'm'"
    assert_equal expect, Bcat::ANSI.new(text).to_html
  end
end
