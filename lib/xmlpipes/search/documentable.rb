module XMLPipes #:nodoc:
  class Search #:nodoc:

    module Documentable

      def document_ids
        results[:matches].map { |thing| thing[:doc] }
      end

      def documents
        results[:matches].map { |thing| document(thing) }
      end

      def each_document(&block)
        raise LocalJumpError unless block_given?
        results[:matches].map { |thing| yield(document(thing)) }
      end

      def document(thing)
        klass = config.class_from_crc(thing[:attributes]['xmlpipes_class_crc'].to_i)
        klass.from_document_id(thing[:doc].to_i)
      end

      private :document

    end

    include Documentable

  end
end