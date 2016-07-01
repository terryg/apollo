require 'sinatra'
require 'logger'
require 'sass'

class App < Sinatra::Base
  
  set :logging, Logger::DEBUG

  get '/' do
    @datafile = Datafile.first(:fields => [:id, :file_name, :s3_fkey],
                               :matched.not => false,
                               :order => [:created_at.desc])
    haml :index
  end

end
