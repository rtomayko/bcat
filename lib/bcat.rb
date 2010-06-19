require 'rack'
require 'bcat/kidgloves'

class Bcat
  VERSION = '0.0.1'
  include Rack::Utils

  def initialize(fds=[$stdin], config={})
    @fds = fds
    @config = {:Host => '127.0.0.1', :Port => 8091}.merge(config)
  end

  def [](key)
    @config[key]
  end

  def call(env)
    [200, {"Content-Type" => "text/html;charset=utf-8"}, self]
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

  def each
    yield "\n" * 1000
    yield "<!DOCTYPE html>\n"
    yield head
    yield "<pre>" if !self[:html]

    begin
      @fds.each do |fd|
        begin
          while buf = fd.readpartial(4096)
            if !self[:html]
              buf = escape_html(buf)
              buf.gsub!(/\n/, "<br>")
            end
            buf = escape_js(buf)
            yield "<script>document.write('#{buf}');</script>"
          end
        rescue EOFError
        ensure
          fd.close rescue nil
        end
      end
    end

    yield "</pre>" if !self[:html]
    yield foot
  end

  def close
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
end
