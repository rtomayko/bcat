require 'rack'
require 'bcat/reader'
require 'bcat/kidgloves'
require 'bcat/browser'

class Bcat
  VERSION = '0.0.1'
  include Rack::Utils

  def initialize(reader, config={})
    @reader = reader
    @config = {:Host => '127.0.0.1', :Port => 8091}.merge(config)
  end

  def [](key)
    @config[key]
  end

  def call(env)
    notice "#{env['REQUEST_METHOD']} #{env['PATH_INFO'].inspect}"
    [200, {"Content-Type" => "text/html;charset=utf-8"}, self]
  end

  def each
    yield "\n" * 1000
    yield "<!DOCTYPE html>\n"
    yield head
    yield "<pre>" if !self[:html]

    @reader.each do |buf|
       if !self[:html]
         buf = escape_html(buf)
         buf.gsub!(/\n/, "<br>")
       end
       buf = escape_js(buf)
       yield "<script>document.write('#{buf}');</script>"
    end

    yield "</pre>" if !self[:html]
    yield foot
  end

  def head
    ["<html>",
     "<head><title>#{self[:title] || 'bcat'}</title></head>",
     "<body>"].join
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

  def notice(message)
    return if !@config[:debug]
    warn "#{File.basename($0)}: #{message}"
  end
end
