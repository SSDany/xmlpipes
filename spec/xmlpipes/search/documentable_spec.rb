require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe XMLPipes::Search::Documentable do

  describe '#documents' do

    it 'works (just a temporary integration test)' do
      search = XMLPipes::Search.new('Misaki', :classes => Book)
      matches = []
      matches << {:attributes => {'xmlpipes_class_crc' => '1809255439'},:doc => '1558914253'}
      search.should_receive(:results).and_return(:matches => matches)
      documents = search.documents
      documents.first.title.should == 'NHK ni Youkoso!'
    end

  end

end