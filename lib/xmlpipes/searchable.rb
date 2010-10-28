module XMLPipes #:nodoc:
  module Searchable

    def self.extended(base)
      base.class_eval do
        def self.from_document_id(document_id, options = {})
          raise NotImplementedError,
                'XMLPipes::Searchable requires you to implement this method yourself. ' \
                'Sorry.'
        end
      end unless XMLPipes == base ||
                 base.methods.include?('from_document_id') ||
                 base.methods.include?(:from_document_id)
    end

    def search(*args)
      XMLPipes::Search.new *search_options(args, :ids_only => false)
    end

    def search_for_ids(*args)
      XMLPipes::Search.new *search_options(args, :ids_only => true)
    end

    private

    # based on:
    # ThinkingSphinx::SearchMethods
    def search_context
      self.class.name == 'Class' ? self : nil
    end

    def search_options(args, overrides = {})
      options = Hash === args.last ? args.pop : {}
      options[:classes] ||= Array(search_context)
      args << options.merge(overrides)
    end

  end
end