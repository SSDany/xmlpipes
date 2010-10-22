require 'xmlpipes/source/schema'
require 'xmlpipes/source/field'
require 'xmlpipes/source/attribute'

module XMLPipes #:nodoc:
  class Source

    attr_reader :name
    attr_reader :index
    attr_reader :defaults

    class InvalidAttributeError < StandardError
    end

    def initialize(name, index)
      @name = name.to_sym
      @index = index
      @defaults = {}
    end

    def default(key, value)
      @defaults[key] = value
    end

    #--
    # http://sphinxsearch.com/docs/current.html#conf-xmlpipe-fixup-utf8
    #
    # Perform Sphinx-side UTF-8 validation and filtering to prevent
    # XML parser from choking on non-UTF-8 documents. Optional, default is 0.
    # Applies to xmlpipe2 source type only.
    #
    # Under certain occasions it might be hard or even impossible to guarantee that the
    # incoming XMLpipe2 document bodies are in perfectly valid and conforming UTF-8 encoding.
    # For instance, documents with national single-byte encodings could sneak into the stream.
    # libexpat XML parser is fragile, meaning that it will stop processing in such cases.
    # UTF8 fixup feature lets you avoid that. When fixup is enabled, Sphinx will preprocess
    # the incoming stream before passing it to the XML parser and replace invalid UTF-8
    # sequences with spaces.
    #++

    def fixup_utf8
      @fixup_utf8 = true
    end

    def delta_name
      "#{@name}_delta_source"
    end

    def delta_path
      "#{File.join(Configuration.instance.pipes_path,delta_name)}.xml"
    end

    def core_name
      "#{@name}_core_source"
    end

    def core_path
      "#{File.join(Configuration.instance.pipes_path,core_name)}.xml"
    end

    def delta
      source = Riddle::Configuration::XMLSource.new(delta_name, 'xmlpipe2')
      source.xmlpipe_command = "cat #{delta_path}"
      source.parent = core_name
      source
    end

    def core
      source = Riddle::Configuration::XMLSource.new(core_name, 'xmlpipe2')
      source.xmlpipe_command = "cat #{core_path}"
      source.xmlpipe_fixup_utf8 = @fixup_utf8
      source
    end

  end
end