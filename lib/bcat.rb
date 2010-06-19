require 'rack'
require 'bcat/kidgloves'

class Bcat
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
     "<head><title>bcat</title></head>",
     "<body><pre>"].join
  end

  def foot
    "</pre></body></html>"
  end

  def each
    yield "\n" * 1000
    yield "<!DOCTYPE html>\n"
    yield head

    begin
      @fds.each do |fd|
        begin
          while buf = fd.readpartial(4096)
            output = escape_html(buf)
            output = output.gsub(/\n/, "<br>")
            yield "<script>document.write('#{output}');</script>"
          end
        rescue EOFError
        ensure
          fd.close rescue nil
        end
      end
    end

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
