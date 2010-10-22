module XMLPipes #:nodoc:
  class Source #:nodoc:

    #--
    # <?xml version="1.0" encoding="utf-8"?>
    # <sphinx:docset>
    # <sphinx:schema>
    #   <sphinx:attr name="tracks_count" type="int"/>
    #   <sphinx:attr name="deleted" type="bool" default="false"/>
    #   <sphinx:attr name="updated_at" type="timestamp"/>
    #   <sphinx:attr name="genres" type="multi"/>
    #   <sphinx:attr name="styles" type="multi"/>
    #   <sphinx:attr name="rating" type="float"/>
    # </sphinx:schema>
    # <sphinx:document id="1340468">
    #   <tracks_count>4</tracks_count>
    #   <deleted>0</deleted>
    #   <rating>4.35</rating>
    #   <genres>1362244494</genres>
    #   <styles>3523896948,2066770622</styles>
    #   <updated_at>1210708800</updated_at>
    # </sphinx:document>
    # </sphinx:docset>
    #++

    class Attribute

      Types = [:int, :timestamp, :str2ordinal, :bool, :float, :multi]

      attr_reader :name, :type, :default

      def initialize(name, type, options = {})
        raise InvalidAttributeError unless Types.include?(type)
        @name = name.to_sym
        @type = type.to_sym
        if options.key?(:default)
          @default = cast(options[:default])
        end
      end

      def to_hash
        hsh = {}
        hsh[:name] = @name
        hsh[:type] = @type
        hsh[:default] = @default if @default
        hsh
      end

      def cast(value)
        XMLPipes::Utils.send(@type, value)
      end

    end

    class Int < Attribute

      #--
      # Unsigned integer attribute declaration. [...]
      # The column value should fit into 32-bit unsigned integer range.
      # Values outside this range will be accepted but wrapped around.
      # For instance, -1 will be wrapped around to 2^32-1 or 4,294,967,295. [...]
      # Attributes with less than default 32-bit size, or bitfields, perform slower.
      # But they require less RAM when using extern storage: such bitfields are packed
      # together in 32-bit chunks in .spa attribute data file. Bit size settings are
      # ignored if using inline storage.
      #++

      Bits = 1..32

      attr_reader :bits

      def initialize(name, options = {})
        @bits = options[:bits] ? options[:bits].to_i : Bits.last
        raise InvalidAttributeError unless Bits.include?(@bits)
        super(name, :int, options)
      end

      def to_hash
        super.merge!(:bits => @bits)
      end

      def cast(value)
        XMLPipes::Utils.int(value, @bits)
      end

    end

  end
end