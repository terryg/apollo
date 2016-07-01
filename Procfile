web: bundle exec rackup config.ru -p $PORT
worker: bundle exec rake jobs:do_search
worker: bundle exec rake jobs:check_torrents
worker: bundle exec rake jobs:match_requests