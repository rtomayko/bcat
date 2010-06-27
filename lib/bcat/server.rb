require 'socket'
require 'stringio'
require 'rack/utils'

class Bcat
  # Simple Rack handler based largely on Scott Chacon's kidgloves library:
  # http://github.com/schacon/kidgloves
  class Server
    attr_accessor :app

    def self.run(app, options={}, &block)
      new(app, options).listen(&block)
    end

    def initialize(app, options={})
      @app = app
      @host = options[:Host] || '0.0.0.0'
      @port = options[:Port] || 8089
    end

    def bind(host, port)
      TCPServer.new(host, port)
    rescue Errno::EADDRINUSE
      port += 1
      retry
    end

    def listen
      server = TCPServer.new(@host, @port)

      yield server if block_given?

      loop do
        socket = server.accept
        socket.sync = true
        log "#{socket.peeraddr[2]} (#{socket.peeraddr[3]})"
        begin
          req = {}

          # parse the request line
          request = socket.gets
          method, path, version = request.split(" ", 3)
          req["REQUEST_METHOD"] = method
          info, query = path.split("?")
          req["PATH_INFO"] = info
          req["QUERY_STRING"] = query

          # parse the headers
          while (line = socket.gets)
            line.strip!
            break if line.size == 0
            key, val = line.split(": ")
            key = key.upcase.gsub('-', '_')
            key = "HTTP_#{key}" if !%w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
            req[key] = val
          end

          # parse the body
          body =
            if len = req['CONTENT_LENGTH']
              socket.read(len.to_i)
            else
              ''
            end

          # process the request
          process_request(req, body, socket)
        ensure
          socket.close if not socket.closed?
        end
      end
    end

    def log(message)
      # $stderr.puts message
    end

    def status_message(code)
      Rack::Utils::HTTP_STATUS_CODES[code]
    end

    def process_request(request, input_body, socket)
      env = {}.replace(request)
      env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
      env["QUERY_STRING"] ||= ""
      env["SCRIPT_NAME"] = ""

      rack_input = StringIO.new(input_body)
      rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

      env.update(
        "rack.version"      => [1,0],
        "rack.input"        => rack_input,
        "rack.errors"       => $stderr,
        "rack.multithread"  => true,
        "rack.multiprocess" => true,
        "rack.run_once"     => false,
        "rack.url_scheme"   => ["yes", "on", "1"].include?(env["HTTPS"]) ? "https" : "http"
      )
      status, headers, body = app.call(env)
      begin
        socket.write("HTTP/1.1 #{status} #{status_message(status)}\r\n")
        headers.each do |k, vs|
          vs.split("\n").each { |v| socket.write("#{k}: #{v}\r\n")}
        end
        socket.write("\r\n")
        body.each { |s| socket.write(s) }
      ensure
        body.close if body.respond_to? :close
      end
    end
  end
end
