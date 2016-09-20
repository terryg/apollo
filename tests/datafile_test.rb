require File.expand_path '../../helpers/test_helper.rb', __FILE__

require 'datafile'

class DatafileTest < MiniTest::Unit::TestCase

  def test_match_ratio_sleater_kinney_no_cities_to_love
    datafile = Datafile.new(:torrent_name => "Sleater Kinney - No Cities To Love (2015)",
                            :file_name => "04 No Cities To Love")
    
    r1 = Request.new(:tweet_text => "@1ApolloBot Sleater Kinney No Cities To Love")    
    assert_in_delta 1.0, datafile.match_ratio(r1)

    r2 = Request.new(:tweet_text => "@1ApolloBot Sleater Kinney Price Tag")    
    assert_equal 0.5, datafile.match_ratio(r2)

    r3 = Request.new(:tweet_text => "@1ApolloBot Sleater-Kinney No Cities To Love")    
    assert_equal 1.0, datafile.match_ratio(r3)

  end
    
end
