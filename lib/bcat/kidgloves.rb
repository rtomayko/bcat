require 'socket'
require 'stringio'

module Rack
  module Handler
    class KidGloves
      attr_accessor :app

      StatusMessage = {
        100 => 'Continue',
        101 => 'Switching Protocols',
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        203 => 'Non-Authoritative Information',
        204 => 'No Content',
        205 => 'Reset Content',
        206 => 'Partial Content',
        300 => 'Multiple Choices',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        305 => 'Use Proxy',
        307 => 'Temporary Redirect',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        402 => 'Payment Required',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        407 => 'Proxy Authentication Required',
        408 => 'Request Timeout',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'Length Required',
        412 => 'Precondition Failed',
        413 => 'Request Entity Too Large',
        414 => 'Request-URI Too Large',
        415 => 'Unsupported Media Type',
        416 => 'Request Range Not Satisfiable',
        417 => 'Expectation Failed',
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Timeout',
        505 => 'HTTP Version Not Supported'
      }

      def self.run(app, options={}, &block)
        new(app, options).listen(&block)
      end

      def initialize(app, options={})
        @app = app
        @host = options[:Host] || '0.0.0.0'
        @port = options[:Port] || 8089
      end

      def listen
        log "Starting server on #{@host}:#{@port}"
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
            method, path, version = request.split(" ")
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
            body = ''
            if (len = req['CONTENT_LENGTH']) && ["POST", "PUT"].member?(method)
              body = socket.read(len.to_i)
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
        StatusMessage[code]
      end

      def process_request(request, input_body, socket)
        env = {}.replace(request)
        env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
        env["QUERY_STRING"] ||= ""
        env["SCRIPT_NAME"] = ""

        rack_input = StringIO.new(input_body)
        rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

        env.update({"rack.version" => [1,0],
                     "rack.input" => rack_input,
                     "rack.errors" => $stderr,
                     "rack.multithread" => true,
                     "rack.multiprocess" => true,
                     "rack.run_once" => false,

                     "rack.url_scheme" => ["yes", "on", "1"].include?(env["HTTPS"]) ? "https" : "http"
                   })
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
end
