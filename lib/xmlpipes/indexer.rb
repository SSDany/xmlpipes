module XMLPipes #:nodoc:
  class Indexer

    def initialize(klass)
      @klass = klass
    end

    def index(i, options = {})
      return unless index = XMLPipes::Index === i && i.klass == @klass ? i : indexes[i.to_sym]
      controller.index(index.delta_name, options) if index.has_deltas?
      controller.index(index.core_name, options)
    end

    alias :reindex :index

    #--
    # http://sphinxsearch.com/docs/current.html#api-func-updateatttributes
    #
    # The updates only work with docinfo=extern storage strategy.
    # They are very fast because they're working fully in RAM, but they can also be
    # made persistent: updates are saved on disk on clean searchd shutdown initiated
    # by SIGTERM signal. With additional restrictions, updates are also possible on
    # MVA attributes; refer to mva_updates_pool directive for details.
    #++

    # === Example:
    # Book.update(:books, [31212, 34523], :published => true, :language_id => 8)
    # Book.update(:books, 31212, :deleted => true)
    #
    def update(i, documents, updates)
      return if (documents = Array(documents)).empty?

      index = XMLPipes::Index === i && i.klass == @klass ? i : indexes[i.to_sym]
      return unless index && index.docinfo.to_s == 'extern'

      documents.map! { |doc| @klass === doc ? doc.document_id : doc }
      attrs, values = [], {}

      index.attributes.each do |a|
        next unless updates.key?(a.name)
        v = a.cast(updates[a.name])
        documents.each { |doc| (values[doc] ||= []) << v }
        attrs << a.name.to_s
      end

      client.update(index.name.to_s, attrs, values) unless attrs.empty?
    end

    alias :update_attributes :update

    #--
    # http://sphinxsearch.com/docs/current.html#delta-updates
    #
    # There's a frequent situation when the total dataset is too big to
    # be reindexed from scratch often, but the amount of new records is rather small.
    # Example: a forum with a 1,000,000 archived posts, but only 1,000 new posts per
    # day. In this case, "live" (almost real time) index updates could be implemented
    # using so called "main+delta" scheme. The idea is to set up two sources and two
    # indexes, with one "main" index for the data which only changes rarely (if ever),
    # and one "delta" for the new documents.
    #
    # http://sphinxsearch.com/docs/current.html#index-merging
    #
    # Merging two existing indexes can be more efficient that indexing the data from
    # scratch, and desired in some cases (such as merging 'main' and 'delta' indexes
    # instead of simply reindexing 'main' in 'main+delta' partitioning scheme).
    # So indexer has an option to do that. Merging the indexes is normally faster than
    # reindexing but still not instant on huge indexes. Basically, it will need to read
    # the contents of both indexes once and write the result once. Merging 100 GB and
    # 1 GB index, for example, will result in 202 GB of IO (but that's still likely
    # less than the indexing from scratch requires).
    #++

    def core(s, *documents, &block)
      source = XMLPipes::Source === s && s.index.klass == @klass ? s : sources[s.to_sym]
      return unless source
      File.atomic_write(source.core_path) { |d| d << render_documents(source, *documents, &block) }
    end

    def delta(s, *documents, &block)
      source = XMLPipes::Source === s && s.index.klass == @klass ? s : sources[s.to_sym]
      return unless source && source.index.has_deltas?
      File.atomic_write(source.delta_path) { |d| d << render_documents(source, *documents, &block) }
    end

    #--
    # http://sphinxsearch.com/docs/current.html#conf-sql-query-killlist
    #
    # Kill-list, or K-list for short, is that something.
    # Kill-list attached to 'delta' will suppress the specified rows from all the
    # preceding indexes, in this case just 'main'. So to get the expected results,
    # we should put all the updated and deleted document IDs into it.
    #++

    def klist(s, *documents)
      return unless (source = sources[s.to_sym]) && source.index.has_deltas?
      documents.map! { |doc| @klass === doc ? doc.document_id : doc }
      File.atomic_write(source.delta_path) { |d| d << render_klist(source, *documents) }
    end

    # === Example:
    # Book.indexer.delta(:books, *books) # "books" source
    # Book.indexer.delta(:manga, *manga) # "manga" source
    # Book.merge(:books, :verbose => true)
    #
    def merge(i, options = {})
      index = XMLPipes::Index === i && i.klass == @klass ? i : indexes[i.to_sym]
      return unless index && index.has_deltas?
      controller.index(index.delta_name, options)
      controller.merge(index.core_name, index.delta_name, options)
    end

    private

    def controller
      XMLPipes::Configuration.instance.controller
    end

    def client
      XMLPipes::Configuration.instance.client
    end

    def indexes
      @indexes ||= begin
        hsh = {}
        @klass.sphinx_pipes.each { |index| hsh[index.name] = index }
        hsh
      end
    end

    def sources
      @sources ||= begin
        hsh = {}
        @klass.sphinx_pipes.each { |index| index.sources.each { |s| hsh[s.name] = s }}
        hsh
      end
    end

    #--
    # http://sphinxsearch.com/docs/current.html#xmlpipe2
    #
    # xmlpipe2 lets you pass arbitrary full-text and attribute data
    # to Sphinx in yet another custom XML format. It also allows to
    # specify the schema (ie. the set of fields and attributes) either
    # in the XML stream itself, or in the source settings.
    #
    # Arbitrary fields and attributes are allowed. They also can occur
    # in the stream in arbitrary order within each document; the order
    # is ignored. There is a restriction on maximum field length; fields
    # longer than 2 MB will be truncated to 2 MB (this limit can be
    # changed in the source).
    #++

    def render_documents(source, *documents, &block)
      with_sphinx_schema(source) { |xml|
        documents.each { |doc|
          doc = yield(doc) if block_given? #FIXME
          xml[:sphinx].document(:id => doc.document_id) {
            source.index.fields.each { |f|
              if doc.respond_to?(f.name)
                value = doc.send(f.name)
                xml.send(f.name, value) { xml.parent.namespace = nil }
              end
            } # fields

            source.index.attrs.each { |a|
              if doc.respond_to?(a.name)
                value = a.cast(doc.send(a.name))
                xml.send(a.name, value) { xml.parent.namespace = nil }
              end
            } # attributes
          } # document
        } # documents
      }
    end

    #--
    # http://sphinxsearch.com/docs/current.html#xmlpipe2
    #
    # sphinx:killlist
    # Optional element, child of sphinx:docset.
    # Contains a number of "id" elements whose contents are document IDs
    # to be put into a kill-list for this index.
    #++

    def render_klist(source, *document_ids)
      with_sphinx_schema(source) { |xml|
        xml[:sphinx].killlist {
          document_ids.each { |doc|
            xml.id_(doc) { xml.parent.namespace = nil }
          } # id
        } # killlist
      }
    end

    def with_sphinx_schema(source, &block)
      builder = Nokogiri::XML::Builder.new { |xml|
        xml.docset('xmlns:sphinx' => 'http://www.sphinxsearch.com') {
          xml.parent.namespace = xml.parent.namespace_definitions.first
          # <sphinx:docset xmlns:sphinx="http://www.sphinxsearch.com">

          xml[:sphinx].schema {
            source.index.fields.each { |f| xml[:sphinx].field(f.to_hash) }
            source.index.attrs.each  { |a|
              o = xml[:sphinx].attr_(a.to_hash)
              o.default = a.cast(source.defaults[a.name]) if source.defaults.key?(a.name)
            } # attr
          } # schema

          yield(xml) if block_given?
        } # docset
      }

      builder.to_xml
    end

  end
end