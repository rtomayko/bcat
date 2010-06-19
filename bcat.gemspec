Gem::Specification.new do |s|
  s.name = 'bcat'
  s.version = '0.0.0'
  s.date = '2010-06-19'

  s.summary     = "browser cat"
  s.description =
    "Concatenate input from standard input, or one or more files, " +
    "and write progressive output to a browser."

  s.authors     = ["Ryan Tomayko"]
  s.email       = "rtomayko@gmail.com"

  # = MANIFEST =
  s.files = %w[
    README
    Rakefile
    bin/bcat
    lib/bcat.rb
    lib/bcat/kidgloves.rb
    bcat.gemspec
  ]
  # = MANIFEST =

  s.default_executable = 'bcat'
  s.executables = ['bcat']

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}
  s.add_dependency 'rack'

  s.extra_rdoc_files = %w[COPYING]

  s.has_rdoc = true
  s.homepage = "http://github.com/rtomayko/bcat/"
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.require_paths = %w[lib]
end
