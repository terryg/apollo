require './init'
require './apollo'

namespace :jobs do
  desc 'Get requests from Twitter mentions timeline.'
  task :get_requests do
    apollo = Apollo.new
    apollo.run
  end
end
  
