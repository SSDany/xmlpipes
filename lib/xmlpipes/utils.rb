require 'zlib'
require 'date'
require 'time'

module XMLPipes #:nodoc:
  module Utils

    module_function

    def bool(value)
      (value == 0 || !value) ? 0 : 1
    end

    def float(value)
      value.to_f
    end

    def timestamp(value)
      case value
      when Float, Integer
        # Time.at(1287579577.99999999) #=> 1287579578
        # value = 10 ** 100000
        # Time.at(value) #=> RangeError: bignum too big to convert into `long'
        Time.at(value).to_i
      when Time
        value.to_i
      else
        value.respond_to?(:to_time) ? 
        value.to_time.to_i :
        Time.parse(value.to_s).to_i
      end
    end

    #--
    # MVAs, or multi-valued attributes, are an important special type
    # of per-document attributes in Sphinx. MVAs make it possible to
    # attach lists of values to every document. They are useful for article
    # tags, product categories, etc. Filtering and group-by (but not sorting)
    # on MVA attributes is supported.
    #
    # Currently, MVA list entries are limited to unsigned 32-bit integers.
    # The list length is not limited, you can have an arbitrary number of values
    # attached to each document as long as RAM permits (.spm file that contains
    # the MVA values will be precached in RAM by searchd).
    #++

    def multi(value)
      # Array(nil) => []
      (Array === value ? value : [value]).map { |v|
        case v
        when TrueClass
          1
        when FalseClass, NilClass
          0
        when Time, Date, DateTime
          self.timestamp(v)
        when String
          Zlib.crc32(v)
        else
          v
        end
      }.join(',')
    end

    def int(value, bits = 32, check_bits = false)
      v = value.to_i
      raise RangeError if check_bits && v.abs.to_s(2).size > bits
      v
    end

    def str2ordinal(value)
      value.to_s
    end

  end
end