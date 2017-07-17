set :rails_env, :qa
set :branch, :develop
set :sidekiq_env, :qa

server '46.101.39.47', user: 'deploy', roles: [:web, :app, :db], primary: true
