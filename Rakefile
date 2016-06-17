require './init'
require './apollo'

namespace :jobs do
  desc 'Get requests from Twitter mentions timeline.'
  task :get_requests do
    apollo = Apollo.new
    apollo.poll_and_record_requests
  end

  desc 'Do search for requests.'
  task :do_search do
    apollo = Apollo.new
    apollo.search_for_magnet_links
  end

  desc 'Add magnet links to Transmission Daemon.'
  task :add_magnets do
    apollo = Apollo.new
    apollo.add_torrents
  end

  desc 'Do all.'
  task :do_all do
    apollo = Apollo.new
    apollo.poll_and_record_requests
    apollo.search_for_magnet_links
    apollo.add_torrents
  end
end
  
