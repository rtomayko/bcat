class Bcat

  # Converts ANSI color sequences to HTML.
  #
  # The ANSI module is based on code from the following libraries:
  #
  # ansi2html.sh:
  #   http://code.google.com/p/wrdese/source/browse/trunk/b/ansi2html.sh?r=5
  #
  # HTML::FromANSI:
  #   http://cpansearch.perl.org/src/NUFFIN/HTML-FromANSI-2.03/lib/HTML/FromANSI.pm
  class ANSI
    ESCAPE = "\x1b"

    # Linux console palette
    STYLES = {
      'ef0'  => 'color:#000',
      'ef1'  => 'color:#A00',
      'ef2'  => 'color:#0A0',
      'ef3'  => 'color:#A50',
      'ef4'  => 'color:#00A',
      'ef5'  => 'color:#A0A',
      'ef6'  => 'color:#0AA',
      'ef7'  => 'color:#AAA',
      'ef8'  => 'color:#555',
      'ef9'  => 'color:#F55',
      'ef10' => 'color:#5F5',
      'ef11' => 'color:#FF5',
      'ef12' => 'color:#55F',
      'ef13' => 'color:#F5F',
      'ef14' => 'color:#5FF',
      'ef15' => 'color:#FFF',
      'eb0'  => 'background-color:#000',
      'eb1'  => 'background-color:#A00',
      'eb2'  => 'background-color:#0A0',
      'eb3'  => 'background-color:#A50',
      'eb4'  => 'background-color:#00A',
      'eb5'  => 'background-color:#A0A',
      'eb6'  => 'background-color:#0AA',
      'eb7'  => 'background-color:#AAA',
      'eb8'  => 'background-color:#555',
      'eb9'  => 'background-color:#F55',
      'eb10' => 'background-color:#5F5',
      'eb11' => 'background-color:#FF5',
      'eb12' => 'background-color:#55F',
      'eb13' => 'background-color:#F5F',
      'eb14' => 'background-color:#5FF',
      'eb15' => 'background-color:#FFF'
    }

    ##
    # The default xterm 256 colour palette

    (0..5).each do |red|
      (0..5).each do |green|
        (0..5).each do |blue|
          c = 16 + (red * 36) + (green * 6) + blue
          r = red   > 0 ? red   * 40 + 55 : 0
          g = green > 0 ? green * 40 + 55 : 0
          b = blue  > 0 ? blue  * 40 + 55 : 0
          STYLES["ef#{c}"] = "color:#%2.2x%2.2x%2.2x" % [r, g, b]
          STYLES["eb#{c}"] = "background-color:#%2.2x%2.2x%2.2x" % [r, g, b]
        end
      end
    end

    (0..23).each do |gray|
      c = gray+232
      l = gray*10 + 8
      STYLES["ef#{c}"] = "color:#%2.2x%2.2x%2.2x" % [l, l, l]
      STYLES["eb#{c}"] = "background-color:#%2.2x%2.2x%2.2x" % [l, l, l]
    end

    def initialize(input)
      @input =
        if input.respond_to?(:to_str)
          [input]
        elsif !input.respond_to?(:each)
          raise ArgumentError, "input must respond to each"
        else
          input
        end
      @stack = []
    end

    def to_html
      buf = []
      each { |chunk| buf << chunk }
      buf.join
    end

    def each
      buf = ''
      @input.each do |chunk|
        buf << chunk
        tokenize(buf) do |tok, data|
          case tok
          when :text
            yield data
          when :display
            case code = data
            when 0        ; yield reset_styles if @stack.any?
            when 1        ; yield push_tag("b") # bright
            when 2        ; #dim
            when 3        ; yield push_tag("u")
            when 5        ; yield push_tag("blink")
            when 7        ; #reverse
            when 8        ; yield push_style("display:none")
            when 9        ; yield push_tag("strike")
            when 30..37   ; yield push_style("ef#{code - 30}")
            when 40..47   ; yield push_style("eb#{code - 40}")
            when 90..97   ; yield push_style("ef#{8 + code - 90}")
            when 100..107 ; yield push_style("eb#{8 + code - 100}")
            end 
          end
        end
      end
      yield buf if !buf.empty?
      yield reset_styles if @stack.any?
      self
    end

    def push_tag(tag, style=nil)
      style = STYLES[style] if style && !style.include?(':')
      @stack.push tag
      [ "<#{tag}",
        (" style='#{style}'" if style),
        ">"
      ].join
    end

    def push_style(style)
      push_tag "span", style
    end

    def reset_styles
      stack, @stack = @stack, []
      stack.reverse.map { |tag| "</#{tag}>" }.join
    end

    def tokenize(text)
      tokens = [
        # characters to remove completely
        [/\A\x08+/, lambda { |m| '' }],

        # ansi escape sequences that mess with the display
        [/\A\x1b\[((?:\d{1,3};?)+)m/, lambda { |m|
          m.chomp(';').split(';').
          each { |code| yield :display, code.to_i };
          '' }],

        # malformed sequences
        [/\A\x1b\[?[\d;]{0,3}/, lambda { |m| '' }],

        # real text
        [/\A([^\x1b\x08]+)/m, lambda { |m| yield :text, m; '' }]
      ]

      while (size = text.size) > 0
        tokens.each do |pattern, sub|
          while text.sub!(pattern) { sub.call($1) }
          end
        end
        break if text.size == size
      end
    end

  end
end
