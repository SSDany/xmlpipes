class Article
  include XMLPipes

  define_pipes(:articles) do |index|

    index.schema do |schema|
      schema.field      :title
      schema.field      :summary
      schema.field      :author
      schema.multi      :tags
      schema.boolean    :deleted, :default => false
      schema.integer    :comments_count, :default => 0
      schema.float      :rating, :default => 0.00
      schema.timestamp  :created_at
    end

  end

end