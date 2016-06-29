require './init'
require './jobs'

namespace :jobs do
  desc 'Get requests from Twitter mentions timeline.'
  task :get_requests do
    jobs = Jobs.new
    jobs.poll_and_record_requests
  end

  desc 'Do search for requests.'
  task :do_search do
    jobs = Jobs.new
    jobs.search_for_magnet_links
  end

  desc 'Add magnet links to Transmission Daemon.'
  task :add_magnets do
    jobs = Jobs.new
    jobs.add_torrents
  end

  desc 'Check on status of torrents.'
  task :check_torrents do
    jobs = Jobs.new
    jobs.poll_transmission_daemon
  end

  desc 'For unmatched requests, find a track.'
  task :match_requests do
    jobs = Jobs.new
    jobs.match_requests
  end

  desc 'Poll Twitter and start Transmission.'
  task :poll_and_start do
    jobs = Jobs.new
    jobs.poll_and_record_requests
    jobs.search_for_magnet_links
    jobs.add_torrents
  end

  desc 'Do all.'
  task :do_all do
    jobs = Jobs.new
    jobs.poll_and_record_requests
    jobs.search_for_magnet_links
    jobs.add_torrents
    jobs.poll_transmission_daemon
    jobs.match_requests
  end


end
  
