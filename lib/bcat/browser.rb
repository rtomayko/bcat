class Bcat
  module Browser
    def browser(url, application=ENV['BCAT_APPLICATION'])
      command = browser_command
      fork do
        [$stdin, $stdout].each { |fd| fd.close }
        ENV['BCAT_ARGS'] = "-a '#{application}'" if !application.to_s.empty?
        ENV['BCAT_URL'] = url
        ENV['BCAT_COMMAND'] = command
        exec "/bin/sh -c \"#{command.gsub(/"/, '\"')}\""
      end
    end

    def browser_command
      return ENV['BCAT_COMMAND'] if !ENV['BCAT_COMMAND'].to_s.empty?

      case `uname`
      when /Linux/  ; 'xdg-open $BCAT_ARGS "$BCAT_URL"'
      when /Darwin/ ; 'open $BCAT_ARGS "$BCAT_URL"'
      else          ; 'firefox "$BCAT_URL"'
      end
    end
  end
end
