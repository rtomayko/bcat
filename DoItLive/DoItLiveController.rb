# DoItLiveController.rb
# DoItLive
#
# Created by Blake Mizerany on 6/27/10.
# Copyright 2010 __MyCompanyName__. All rights reserved.

class DoItLiveController < NSWindowController

  Options = { }

  attr_accessor :view

  def self.run?
    Options.has_key?(:url)
  end

  def awakeFromNib
    fail "Missing required options" if !self.class.run?
    url = Options[:url]
    req = NSURLRequest.requestWithURL(NSURL.URLWithString(url))
    view.mainFrame.loadRequest(req)
  end

end
