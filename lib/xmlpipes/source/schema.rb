module XMLPipes #:nodoc:
  class Source #:nodoc:

    #--
    # http://sphinxsearch.com/docs/current.html#xmlpipe2
    #
    # The schema, ie. complete fields and attributes list, must be declared before
    # any document could be parsed. This can be done either in the configuration file
    # using xmlpipe_field and xmlpipe_attr_XXX settings, or right in the stream using
    # <sphinx:schema> element. <sphinx:schema> is optional. It is only allowed to occur
    # as the very first sub-element in <sphinx:docset>. If there is no in-stream schema
    # definition, settings from the configuration file will be used.
    # Otherwise, stream settings take precedence.
    #++

    class Schema

      attr_reader :fields
      attr_reader :attrs
      attr_reader :index

      def initialize(index, options = {})
        @fields = []
        @attrs  = []
        @index  = index
      end

      #--
      # http://sphinxsearch.com/docs/current.html#xmlpipe2
      #
      # sphinx:field
      # Optional element, child of sphinx:schema.
      # Declares a full-text field. Known attributes are:
      # * name, specifies the XML element name that will be treated
      #   as a full-text field in the subsequent documents.
      # * attr, specifies whether to also index this field as a string
      #   or word count attribute. Possible values are "string" and "wordcount".
      #   Introduced in version 1.10-beta.
      #++

      def indexes(fieldname, options = {})
        @fields << Source::Field.new(fieldname, options)
      end

      alias :field :indexes

      #--
      # http://sphinxsearch.com/docs/current.html#xmlpipe2
      #
      # sphinx:attr
      # Optional element, child of sphinx:schema.
      # Declares an attribute. Known attributes are: 
      # * name, specifies the element name that should be treated
      #   as an attribute in the subsequent documents.
      # * type, specifies the attribute type.
      #   Possible values are "int", "timestamp", "str2ordinal", "bool", "float" and "multi".
      # * bits, specifies the bit size for "int" attribute type.
      #   Valid values are 1 to 32.
      # * default, specifies the default value for this attribute that
      #   should be used if the attribute's element is not present in the document.
      #++

      def boolean(attrname, options = {})
        @attrs << Source::Attribute.new(attrname, :bool, options)
      end

      alias :bool :boolean

      def integer(attrname, options = {})
        @attrs << Source::Int.new(attrname, options)
      end

      alias :int :integer

      def float(attrname, options = {})
        @attrs << Source::Attribute.new(attrname, :float, options)
      end

      def timestamp(attrname, options = {})
        @attrs << Source::Attribute.new(attrname, :timestamp, options)
      end

      def multi(attrname, options = {})
        @attrs << Source::Attribute.new(attrname, :multi, options)
      end

      #--
      # http://sphinxsearch.com/docs/current.html#conf-xmlpipe-attr-str2ordinal
      # http://sphinxsearch.com/docs/current.html#conf-sql-attr-str2ordinal
      #
      # Note that the ordinals are by construction local to each index,
      # and it's therefore impossible to merge ordinals while retaining the proper order.
      # The processed strings are replaced by their sequential number in the index they
      # occurred in, but different indexes have different sets of strings.
      # For instance, if 'main' index contains strings "aaa", "bbb", "ccc", and
      # so on up to "zzz", they'll be assigned numbers 1, 2, 3, and so on up to 26,
      # respectively. But then if 'delta' only contains "zzz" the assigned number will be 1.
      # And after the merge, the order will be broken. Unfortunately, this is impossible
      # to workaround without storing the original strings (and once Sphinx supports
      # storing the original strings, ordinals will not be necessary any more).
      #++

      def ordinal(attrname, options = {})
        @attrs << Source::Attribute.new(attrname, :str2ordinal, options)
      end

      alias :str2ordinal :ordinal

    end
  end
end