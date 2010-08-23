Gem::Specification.new do |s|
  s.name = 'bcat'
  s.version = '0.5.2'
  s.date = '2010-08-23'

  s.description = "pipe to browser utility"
  s.summary =
    "Concatenate input from standard input, or one or more files, " +
    "and write progressive output to a browser."

  s.authors     = ["Ryan Tomayko"]
  s.email       = "rtomayko@gmail.com"

  # = MANIFEST =
  s.files = %w[
    CONTRIBUTING
    COPYING
    INSTALLING
    README
    Rakefile
    bcat.gemspec
    bin/a2h
    bin/bcat
    bin/btee
    contrib/bman
    lib/bcat.rb
    lib/bcat/ansi.rb
    lib/bcat/browser.rb
    lib/bcat/html.rb
    lib/bcat/reader.rb
    lib/bcat/server.rb
    man/a2h.1
    man/a2h.1.ronn
    man/bcat.1
    man/bcat.1.ronn
    man/btee.1
    man/btee.1.ronn
    man/index.html
    test/contest.rb
    test/test_bcat_a2h.rb
    test/test_bcat_ansi.rb
    test/test_bcat_browser.rb
    test/test_bcat_head_parser.rb
  ]
  # = MANIFEST =

  s.default_executable = 'bcat'
  s.executables = ['a2h', 'bcat', 'btee']

  s.test_files = s.files.select {|path| path =~ /^test\/.*_test.rb/}
  s.add_dependency 'rack', '< 1.2'

  s.extra_rdoc_files = %w[COPYING]

  s.has_rdoc = true
  s.homepage = "http://rtomayko.github.com/bcat/"
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.require_paths = %w[lib]
end
