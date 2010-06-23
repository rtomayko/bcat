require 'rack'
require 'bcat/reader'
require 'bcat/ansi'
require 'bcat/html'
require 'bcat/kidgloves'
require 'bcat/browser'

class Bcat
  VERSION = '0.3.0'
  include Rack::Utils

  attr_reader :format

  def initialize(files=[], config={})
    @config = {:Host => '127.0.0.1', :Port => 8091}.merge(config)
    @reader = Bcat::Reader.new(files)
    @format = @config[:format] || @reader.sniff

    @filter = @reader
    @filter = TeeFilter.new(@filter) if @config[:tee]
    @filter = TextFilter.new(@filter) if @format == 'text'
    @filter = ANSI.new(@filter) if @format == 'text' || @config[:ansi]
  end

  def [](key)
    @config[key]
  end

  def to_app
    app = self
    Rack::Builder.new do
      use Rack::Chunked
      run app
    end
  end

  def serve!(&bk)
    Rack::Handler::KidGloves.run to_app, @config, &bk
  end

  def call(env)
    notice "#{env['REQUEST_METHOD']} #{env['PATH_INFO'].inspect}"
    [200, {"Content-Type" => "text/html;charset=utf-8"}, self]
  end

  def each
    head_parser = Bcat::HeadParser.new

    @filter.each do |buf|
      if head_parser.nil?
        yield buf
      elsif head_parser.feed(buf)
        yield content_for_head(inject=head_parser.head)
        yield head_parser.body
        head_parser = nil
      end
    end

    if head_parser
      yield content_for_head(inject=head_parser.head) +
            head_parser.body
    end

    yield foot
  rescue Errno::EINVAL
    # socket was closed
    notice "browser client went away"
  rescue => boom
    notice "boom: #{boom.class}: #{boom.to_s}"
    raise
  end

  def content_for_head(inject='')
    [
      "\n" * 1000,
      "<!DOCTYPE html>",
      "<html>",
      "<head>",
      "<!-- bcat was here -->",
      "<title>#{self[:title] || 'bcat'}</title>",
      inject.to_s,
      "</head>"
    ].join("\n")
  end

  def foot
    "</body></html>"
  end

  def escape_js(string)
    string = string.gsub(/['\\]/) { |char| "\\#{char}" }
    string.gsub!(/\n/, '\n')
    string
  end

  def close
    notice "closing with interrupt"
    raise Interrupt
  end

  def notice(message)
    return if !@config[:debug]
    warn "#{File.basename($0)}: #{message}"
  end
end
