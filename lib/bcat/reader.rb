require 'rack/utils'

class Bcat
  # ARGF style multi-file streaming interface. Input is read with IO#readpartial
  # to avoid buffering.
  class Reader
    attr_reader :files
    attr_reader :fds

    def initialize(files=[])
      @files = files
      @fds =
        files.map do |f|
          if f == '-'
            $stdin
          else
            File.open(f, 'rb')
          end
        end
    end

    def each
      fds.each do |fd|
        fd.sync = true
        begin
          while buf = fd.readpartial(4096)
            yield buf
          end
        rescue EOFError
        ensure
          fd.close
        end
      end
    end
  end

  # Like Reader but writes all input to an output IO object in addition to
  # yielding to the block.
  class TeeReader < Reader
    def initialize(files=[], out=$stdout)
      @out = out
      super(files)
    end

    def each
      super() do |chunk|
        @out.write chunk
        yield chunk
      end
    end
  end

  class TextFilter
    include Rack::Utils

    def initialize(source)
      @source = source
    end

    def each
      yield "<pre>"
      @source.each do |chunk|
        chunk = escape_html(chunk)
        chunk = "<span>#{chunk}</span>" if !chunk.gsub!(/\n/, "<br>")
        yield chunk
      end
      yield "</pre>"
    end
  end
end
