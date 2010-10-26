require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Index do

  before(:all) do
    XMLPipes::Configuration.instance.send(:searchd_file_path=, '/path/to/indexes')
  end

  before(:each) do
    @index = XMLPipes::Index.new(:spec, Article)
  end

  it 'has no deltas by default' do
    @index.should_not have_deltas
  end

  describe '#enable_deltas' do

    it 'enables deltas' do
      @index.enable_deltas
      @index.should have_deltas
    end

  end

  describe '#schema' do

    it 'creates and yields a new instance of the XMLPipes::Source::Schema' do
      expected = nil
      @index.schema { |schema| expected = schema }
      expected.should be_an_instance_of XMLPipes::Source::Schema
      expected.index.should == @index
    end

    it 'also creates one (default) source if necessary' do
      @index.schema { |schema| }
      @index.sources.size.should == 1
      @index.sources.first.name.should == :spec
    end

    it 'one more spec, please (declaration of the schema after declaration of the source)'

  end

  describe '#source' do

    it 'creates and yields a new instance of the XMLPipes::Source' do
      expected = nil
      @index.source { |source| expected = source }
      expected.should be_an_instance_of XMLPipes::Source
      expected.index.should == @index
    end

    it 'appends the list of sources with new source' do
      expected = nil
      @index.source { |source| expected = source }
      @index.sources.size.should == 1
      @index.sources.first.should == expected
    end

    it 'defaults name of the source to the name of the index' do
      @index.source {}
      @index.sources.first.name.should == :spec
    end

    it 'allows to create source with custom name' do
      @index.source(:things) {}
      @index.sources.first.name.should == :things
    end

    it 'allows to create multiple sources' do
      @index.source(:one) {}
      @index.source(:two) {}
      @index.sources.size.should == 2
      @index.sources[0].name.should == :one
      @index.sources[1].name.should == :two
    end

    it 'keeps sources uniqued by name' do
      @index.source(:things) { |source|  }
      @index.sources.size.should == 1
      source = @index.sources.first
      source_object_id = source.object_id

      @index.source(:things) { |source|  }
      @index.sources.size.should == 1
      new_source = @index.sources.first
      new_source.object_id.should_not == source_object_id
    end

  end

  describe '#attributes' do
    it 'returns a full list of attributes (include xmlpipes_class_crc)' do
      @index.schema do |schema|
        schema.timestamp :created_at
        schema.timestamp :updated_at
        schema.bool :deleted
      end
      @index.attributes.size.should == 4
      @index.attributes.map { |a| a.name }.should == [:xmlpipes_class_crc, :created_at, :updated_at, :deleted]
    end
  end

  describe '#fields' do
    it 'returns a full list of fields' do
      @index.schema do |schema|
        schema.indexes :profile
        schema.indexes :description
        schema.indexes :summary
      end
      @index.fields.size.should == 3
      @index.fields.map { |a| a.name }.should == [:profile, :description, :summary]
    end
  end

  describe '#delta' do

    before(:each) do
      XMLPipes::Source.should_receive(:new).and_return(
        mock(:source, :name => :one, :delta => 'one_delta_source'),
        mock(:source, :name => :two, :delta => 'two_delta_source'))
      @index.source(:one) { }
      @index.source(:two) { }
    end

    before(:each) do
      lambda { @delta = @index.send(:delta) }.should_not raise_error
    end

    it 'returns an instance of the Riddle::Configuration::Index' do
      @delta.should be_an_instance_of Riddle::Configuration::Index
    end

    it 'uses proper name' do
      @delta.name.should == 'spec_delta'
    end

    it 'uses proper path' do
      @delta.path.should == '/path/to/indexes/spec_delta'
    end

    it 'uses proper sources' do
      @delta.sources.should == %w(one_delta_source two_delta_source)
    end

    it 'uses "core" as a parent' do
      @delta.parent.should == 'spec_core'
    end

  end

  describe '#core' do

    before(:each) do
      XMLPipes::Source.should_receive(:new).and_return(
        mock(:source, :name => :one, :core => 'one_core_source'),
        mock(:source, :name => :two, :core => 'two_core_source'))
      @index.source(:one) { }
      @index.source(:two) { }
    end

    before(:each) do
      lambda { @core = @index.send(:core) }.should_not raise_error
    end

    it 'returns an instance of the Riddle::Configuration::Index' do
      @core.should be_an_instance_of Riddle::Configuration::Index
    end

    it 'uses proper name' do
      @core.name.should == 'spec_core'
    end

    it 'uses proper path' do
      @core.path.should == '/path/to/indexes/spec_core'
    end

    it 'uses proper sources' do
      @core.sources.should == %w(one_core_source two_core_source)
    end

    it 'has NO parent' do
      @core.parent.should be_nil
    end

    it 'uses user-defined docinfo, if any' do
      @index.set :docinfo, :none
      @index.schema { |shema| shema.bool :deleted }
      @index.docinfo.should == :none
      @index.send(:core).docinfo.should == :none
    end

    it 'defaults docinfo to :extern otherwise' do
      @index.schema { |schema| schema.bool :deleted }
      @index.docinfo.should == :extern
      @index.send(:core).docinfo.should == :extern
    end

  end

  describe '#distributed' do

    describe 'with deltas' do

      before(:each) do
        @index.enable_deltas
        lambda { @distributed = @index.send(:distributed) }.should_not raise_error
      end

      it 'returns an instance of the Riddle::Configuration::DistributedIndex' do
        @distributed.should be_an_instance_of Riddle::Configuration::DistributedIndex
      end

      it 'uses proper name' do
        @distributed.name.should == 'spec'
      end

      it 'uses proper list of local indexes (core and delta)' do
        @distributed.local_indexes.should == %w(spec_core spec_delta)
      end

    end

    describe 'without deltas' do

      before(:each) do
        lambda { @distributed = @index.send(:distributed) }.should_not raise_error
      end

      it 'returns an instance of the Riddle::Configuration::DistributedIndex' do
        @distributed.should be_an_instance_of Riddle::Configuration::DistributedIndex
      end

      it 'uses proper name' do
        @distributed.name.should == 'spec'
      end

      it 'uses proper local index (core)' do
        @distributed.local_indexes.should == %w(spec_core)
      end

    end

  end

  describe '#to_riddle' do

    describe 'with deltas' do
      it 'returns configurations for indexes (core, delta and distributed)' do
        @index.enable_deltas
        indexes = @index.to_riddle
        indexes.should be_an_instance_of Array
        indexes.size.should == 3
        indexes[0].should be_an_instance_of Riddle::Configuration::Index
        indexes[0].name.should == 'spec_core'
        indexes[1].should be_an_instance_of Riddle::Configuration::Index
        indexes[1].name.should == 'spec_delta'
        indexes[2].should be_an_instance_of Riddle::Configuration::DistributedIndex
        indexes[2].name.should == 'spec'
      end
    end

    describe 'without deltas' do
      it 'returns configurations for indexes (core and distributed)' do
        indexes = @index.to_riddle
        indexes.should be_an_instance_of Array
        indexes.size.should == 2
        indexes[0].should be_an_instance_of Riddle::Configuration::Index
        indexes[0].name.should == 'spec_core'
        indexes[1].should be_an_instance_of Riddle::Configuration::DistributedIndex
        indexes[1].name.should == 'spec'
      end
    end

  end

  after(:all) do
    XMLPipes::Configuration.instance.reset
  end

end