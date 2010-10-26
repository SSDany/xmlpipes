module XMLPipes #:nodoc:
  module Searchable

    def self.extended(klass)
      klass.class_eval do
        def self.from_document_id(document_id, options = {})
          raise NotImplementedError,
                'XMLPipes::Searchable requires you to implement this method yourself. ' \
                'Sorry.'
        end
      end unless klass.methods.include?('from_document_id') ||
                 klass.methods.include?(:from_document_id)
    end

    def search(*args)
      options = Hash === args.last ? args.pop : {}
      options[:classes] = self
      XMLPipes::Search.new(args, options)
    end

  end
end