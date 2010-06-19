require 'date'

require 'rubygems'
$spec = eval(File.read('bcat.gemspec'))

desc "Build gem package"
task :package => 'bcat.gemspec' do
  sh "gem build bcat.gemspec"
end

desc 'Build the manual'
task :man do
  ENV['RONN_MANUAL']  = "Bcat #{source_version}"
  ENV['RONN_ORGANIZATION'] = "Ryan Tomayko"
  sh "ronn -w -r5 man/*.ronn"
end

def source_version
  @source_version ||= `ruby -Ilib -rbcat -e 'puts Bcat::VERSION'`.chomp
end

file 'bcat.gemspec' => FileList['{lib,test,bin}/**','Rakefile'] do |f|
  # read spec file and split out manifest section
  spec = File.read(f.name)
  head, manifest, tail = spec.split("  # = MANIFEST =\n")
  # replace version and date
  head.sub!(/\.version = '.*'/, ".version = '#{source_version}'")
  head.sub!(/\.date = '.*'/, ".date = '#{Date.today.to_s}'")
  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").
    sort.
    reject{ |file| file =~ /^\./ }.
    reject { |file| file =~ /^doc/ }.
    map{ |file| "    #{file}" }.
    join("\n")
  # piece file back together and write...
  manifest = "  s.files = %w[\n#{files}\n  ]\n"
  spec = [head,manifest,tail].join("  # = MANIFEST =\n")
  File.open(f.name, 'w') { |io| io.write(spec) }
  puts "updated #{f.name}"
end
