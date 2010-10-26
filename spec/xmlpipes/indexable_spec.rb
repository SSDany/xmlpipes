require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Indexable do

  before(:each) do
    @class = Class.new { extend XMLPipes::Indexable }
  end

  describe '#indexer' do

    it 'is an instance of the XMLPipes::Indexer' do
      @class.indexer.should be_an_instance_of XMLPipes::Indexer
    end

    it 'has a proper @klass' do
      @class.indexer.instance_variable_get(:@klass).should == @class
    end

  end

  describe '#to_riddle' do

    it 'iterates through indexes and collects configs' do
      @class.define_pipes(:one) { |index| @index1 = index }
      @class.define_pipes(:two) { |index| @index2 = index }

      @index1.should_receive(:to_riddle).and_return([:one_core, :one_delta, :one_distributed])
      @index2.should_receive(:to_riddle).and_return([:two_core, :two_delta, :two_distributed])
      @class.to_riddle.should == [
        :one_core, :one_delta, :one_distributed,
        :two_core, :two_delta, :two_distributed]
    end

  end

  it 'exposes indexes' do
    @class.should respond_to(:sphinx_pipes)
    @class.sphinx_pipes.should be_an_instance_of ::Array
    @class.should_not have_sphinx_pipes
    @class.define_pipes(:spec) { |index|  }
    @class.sphinx_pipes.size.should == 1
    @class.should have_sphinx_pipes
  end

  it 'provides the #define_pipes method' do
    @class.should respond_to(:define_pipes)
  end

  describe '#define_pipes' do

    it 'creates and yields a new instance of the XMLPipes::Index' do
      expected = nil
      @class.define_pipes(:spec) { |index| expected = index }
      expected.should be_an_instance_of XMLPipes::Index
      expected.name.should == :spec
    end

    it 'notifies XMLPipes::Configuration about the indexed class' do
      XMLPipes::Configuration.instance.should_receive(:indexed).with(@class)
      @class.define_pipes(:spec) { |index| }
    end

    it 'appends the list of indexes with new index' do
      @class.define_pipes(:spec) { |index| }
      sphinx_pipes = @class.send(:sphinx_pipes)
      sphinx_pipes.size.should == 1
      sphinx_pipes.first.should be_an_instance_of XMLPipes::Index
      sphinx_pipes.first.name.should == :spec
    end

    it 'keeps indexes uniqued by name' do
      @class.define_pipes(:spec) { |index| }
      sphinx_pipes = @class.send(:sphinx_pipes)
      index_object_id = sphinx_pipes.first.object_id

      @class.define_pipes(:spec) { |index| }
      sphinx_pipes = @class.send(:sphinx_pipes)
      sphinx_pipes.size.should == 1
      sphinx_pipes.first.object_id.should_not == index_object_id
    end

  end

  it 'provides the #document_id method (attr_reader)' do
    @class.new.should respond_to(:document_id)
  end

  it 'does not override the #document_id method' do
    klass = Class.new { def document_id; 42; end }
    klass.new.document_id.should == 42
    klass.extend XMLPipes::Indexable
    klass.new.document_id.should == 42
  end

end