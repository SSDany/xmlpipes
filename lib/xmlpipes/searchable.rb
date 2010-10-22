module XMLPipes
  module Searchable

    def search(*args)
      options = Hash === args.last ? args.pop : {}
      options[:classes] = self
      XMLPipes::Search.new(args, options)
    end

  end
end