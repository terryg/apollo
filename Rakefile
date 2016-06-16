require './init'
require './apollo.rb'

namespace :jobs do
  desc 'Get requestes from Twitter mentions timeline.'
  task :get_requests do
    apollo = Apollo.new
    apollo.run
  end
end
  
