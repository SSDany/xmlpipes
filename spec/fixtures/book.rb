class Book
  include XMLPipes

  attr_accessor :document_id
  attr_accessor :title, :description, :authors, :publisher
  attr_accessor :tags, :volumes

  def self.from_document_id(document_id)
    YAML.load_file(File.join(File.dirname(__FILE__), "yml/#{document_id}.yml"))
  end

  define_pipes(:titles) do |index|
    index.schema { |schema| schema.field :title }
  end

  define_pipes(:books) do |index|

    index.schema do |schema|
      schema.field    :title
      schema.field    :description
      schema.field    :authors
      schema.field    :publisher
      schema.multi    :tags
      schema.integer  :volumes, :bits => 8, :default => 1
      schema.boolean  :deleted, :default => false
    end

    # this source already exists
    index.source :books do |source|
      source.default :tags, :book
    end

    # another source will be created
    index.source :manga do |source|
      source.default :tags, :manga
    end

    index.enable_deltas

    index.set :prefix_field_names  , %w(title authors publisher)
    index.set :infix_field_names   , %w(title authors publisher)

  end

end
