require 'xmlpipes/configuration'
require 'xmlpipes/controller'
require 'xmlpipes/index'
require 'xmlpipes/indexable'
require 'xmlpipes/indexer'
require 'xmlpipes/search'
require 'xmlpipes/searchable'
require 'xmlpipes/source'
require 'xmlpipes/utils'
require 'xmlpipes/version'
require 'xmlpipes/core_ext/file'

module XMLPipes

  def self.append_features(klass)
    klass.extend XMLPipes::Indexable
    klass.extend XMLPipes::Searchable
  end

  extend XMLPipes::Searchable

end