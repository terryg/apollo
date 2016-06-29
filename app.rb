class App < Sinatra::Base

  get '/' do
    @tracks = Track.all(:order => [:created_at.desc])
    haml :index
  end

end
