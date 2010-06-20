class Bcat

  # Parses HTML until the first displayable body character and provides methods
  # for accessing head and body contents.
  class HeadParser
    attr_accessor :buf

    def initialize
      @buf = ''
      @head = []
      @body = nil
      @html = nil
    end

    # Called to parse new data as it arrives.
    def feed(data)
      if complete?
        @body << data
      else
        @buf << data
        parse(@buf)
      end
      complete?
    end

    # Truthy once the first displayed character of the body has arrived.
    def complete?
      !@body.nil?
    end

    # Determine if the input is HTML. This nil before the first non-whitespace
    # character is received, true if the first non-whitespace character is a
    # '<', and false if the first non-whitespace character is something other
    # than '<'.
    def html?
      @html
    end

    # The head contents without any DOCTYPE, <html>, or <head> tags. This should
    # consist of only <style>, <script>, <link>, <meta>, and <title> tags.
    def head
      @head.join.gsub(/<\/?(?:html|head|!DOCTYPE).*?>/mi, '')
    end

    # The current body contents. The <body> tag is guaranteed to be present. If
    # a <body> was included in the input, it's preserved with original
    # attributes; otherwise, a <body> tag is inserted. The inject argument can
    # be used to insert a string as the immediate descendant of the <body> tag.
    def body(inject=nil)
      if @body =~ /\A\s*(<body.*?>)(.*)/mi
        [$1, inject, $2].compact.join("\n")
      else
        ["<body>", inject, @body].compact.join("\n")
      end
    end

    HEAD_TOKS = [
      /\A(<!DOCTYPE.*?>)/m,
      /\A(<title.*?>.*?<\/title>)/mi,
      /\A(<script.*?>.*?<\/script>)/mi,
      /\A(<style.*?>.*?<\/style>)/mi,
      /\A(<(?:html|head|meta|link).*?>)/mi,
      /\A(<\/(?:html|head|meta|link|script|style|title)>)/mi,
      /\A(<!--(.*?)-->)/m
    ]

    BODY_TOKS = [
      /\A[^<]/,
      /\A<(?!html|head|meta|link|script|style|title).*?>/
    ]

    # Parses buf into head and body parts. Basic approach is to eat anything
    # possibly body related until we hit text or a body element.
    def parse(buf=@buf)
      if @html.nil?
        if buf =~ /\A\s*[<]/m
          @html = true
        elsif buf =~ /\A\s*[^<]/m
          @html = false
        end
      end

      while !buf.empty?
        buf.sub!(/\A(\s+)/m) { @head << $1 ; '' }
        matched =
          HEAD_TOKS.any? do |tok|
            buf.sub!(tok) do
              @head << $1
              ''
            end
          end
        break unless matched
      end


      if buf.empty?
        buf
      elsif BODY_TOKS.any? { |tok| buf =~ tok }
        @body = buf
        nil
      else
        buf
      end
    end
  end
end
