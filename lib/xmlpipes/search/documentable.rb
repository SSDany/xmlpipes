module XMLPipes #:nodoc:
  class Search #:nodoc:

    module Documentable

      def method_missing(method_id, *args, &block)
        if @array.respond_to?(method_id)
          self.class.class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{method_id}(*args, &block); self.to_a.#{method_id}(*args,&block); end
          METHOD
          send(method_id, *args, &block)
        else
          raise NoMethodError # TODO: message
        end
      end

      def respond_to?(*args)
        super || @array.respond_to?(*args)
      end

      private

      def document_ids
        results[:matches].map { |thing| thing[:doc] }
      end

      def documents
        results[:matches].map { |thing| document(thing) }
      end

      def document(thing)
        klass = config.class_from_crc(thing[:attributes]['xmlpipes_class_crc'].to_i)
        klass.from_document_id(thing[:doc].to_i)
      end

    end

    include Documentable

  end
end