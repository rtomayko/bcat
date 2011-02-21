class Bcat
  class Browser
    ENVIRONMENT =
      case `uname`
      when /Darwin/       ; 'Darwin'
      when /Linux/, /BSD/ ; 'X11'
      else                  'X11'
      end

    # browser name -> command mappings
    COMMANDS = {
      'Darwin' => {
        'default'     => "open",
        'safari'      => "open -a Safari",
        'firefox'     => "open -a Firefox",
        'chrome'      => "open -a Google\\ Chrome",
        'chromium'    => "open -a Chromium",
        'opera'       => "open -a Opera",
        'curl'        => "curl -s"
      },

      'X11'  => {
        'default'     => "xdg-open",
        'firefox'     => "firefox",
        'chrome'      => "google-chrome",
        'chromium'    => "chromium",
        'mozilla'     => "mozilla",
        'epiphany'    => "epiphany",
        'curl'        => "curl -s"
      }
    }

    # alternative names for browsers
    ALIASES = {
      'google-chrome' => 'chrome',
      'google chrome' => 'chrome',
      'gnome'         => 'epiphany'
    }

    def initialize(browser, command=ENV['BCAT_COMMAND'])
      @browser = browser
      @command = command
    end

    def open(url)
      fork do
        $stdin.close
        exec "#{command} #{shell_quote(url)}"
        exit! 128
      end
    end

    def command
      @command || browser_command
    end

    def browser_command(browser=@browser)
      browser ||= 'default'
      browser = browser.downcase
      browser = ALIASES[browser] || browser
      COMMANDS[ENVIRONMENT][browser]
    end

    def shell_quote(argument)
      '"' + argument.to_s.gsub(/([\\"`$])/) { "\\" + $1 } + '"'
    end
  end
end
