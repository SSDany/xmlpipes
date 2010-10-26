module XMLPipes
  module Searchable

    def self.extended(klass)
      # TODO:
      # check if klass respond to #from_document_id
      # and define this method if not.
    end

    def search(*args)
      options = Hash === args.last ? args.pop : {}
      options[:classes] = self
      XMLPipes::Search.new(args, options)
    end

  end
end