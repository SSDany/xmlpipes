require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Source do

  before(:all) do
    XMLPipes::Configuration.instance.send(:pipes_path=, '/path/to/pipes')
  end

  before(:each) do
    @source = XMLPipes::Source.new(:spec, :index)
  end

  describe '#delta' do

    before(:each) do
      lambda { @delta = @source.delta }.should_not raise_error
    end

    it 'returns an instance of the Riddle::Configuration::XMLSource' do
      @delta.should be_an_instance_of Riddle::Configuration::XMLSource
    end

    it 'uses proper name' do
      @delta.name.should == 'spec_delta_source'
    end

    it 'uses proper xmlpipe_command' do
      @delta.xmlpipe_command.should == 'cat /path/to/pipes/spec_delta_source.xml'
    end

    it 'uses "core" as a parent' do
      @delta.parent.should == 'spec_core_source'
    end

  end

  describe '#core' do

    before(:each) do
      lambda { @core = @source.core }.should_not raise_error
    end

    it 'returns an instance of the Riddle::Configuration::XMLSource' do
      @core.should be_an_instance_of Riddle::Configuration::XMLSource
    end

    it 'uses proper name' do
      @core.name.should == 'spec_core_source'
    end

    it 'uses proper xmlpipe_command' do
      @core.xmlpipe_command.should == 'cat /path/to/pipes/spec_core_source.xml'
    end

    it 'has NO parent' do
      @core.parent.should be_nil
    end

    it 'uses the xmlpipe_fixup_utf8 flag if necessary' do
      @source.fixup_utf8
      @source.core.xmlpipe_fixup_utf8.should be_true
    end

  end

  after(:all) do
    XMLPipes::Configuration.instance.reset
  end

end