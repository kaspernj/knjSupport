#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require "knj/autoload"
include Knj
include GetText

require "config/ssh_server"

require "windows/win_main"
Win_main.new

Gtk.main