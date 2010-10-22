module XMLPipes #:nodoc:
  class Source #:nodoc:

    #--
    # <?xml version="1.0" encoding="utf-8"?>
    # <sphinx:docset>
    # <sphinx:schema>
    #   <sphinx:field name="name"/>
    #   <sphinx:field name="realname"/>
    #   <sphinx:field name="profile"/>
    # </sphinx:schema>
    # <sphinx:document id="25958">
    #   <name>Angerfist</name>
    #   <realname>Danny Masseling</realname>
    #   <profile>
    #     Danny Masseling started making music at the age of 16. Beginning with 4-beat programmed
    #     loops and breakbeatz etc, his interest in producing music started to grow. It almost
    #     became an obession, and in the the same addicitive way as a crack junk smokes his dope,
    #     Danny worked on his music day and night. Always searching for improvement and development,
    #     his music became more and more professional...
    #   </profile>
    # </sphinx:document>
    # </sphinx:docset>
    #++

    class Field

      Attrs = [:string, :wordcount]

      attr_reader :name

      def initialize(name, options = {})
        @name = name.to_sym
      end

      def to_hash
        {:name => @name}
      end

    end
  end
end