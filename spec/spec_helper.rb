require 'pathname'
require 'rubygems'
require 'bundler'

Bundler.require(:default, :development)

SPEC_ROOT = Pathname(__FILE__).dirname.expand_path
dir = SPEC_ROOT.parent.join('lib').to_s
$:.unshift(dir) unless $:.include?(dir)

require 'xmlpipes'
require 'fixtures/book.rb'
