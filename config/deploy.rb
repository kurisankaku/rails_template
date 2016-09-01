# config valid only for current version of Capistrano
lock '3.6.1'

# Application name.
set :application, 'rails_template'
set :repo_url, 'git@github.com:kurisankaku/rails_template.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'
set :deploy_to, "/var/www/#{application}"

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# rbenv settings. see: https://github.com/capistrano/rbenv/
# config/deploy.rb
set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.3.1p112'

# in case you want to set ruby version from the file:
# set :rbenv_ruby, File.read('.ruby-version').strip

set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value

# rails settings. see: https://github.com/capistrano/rails/
# :rails_env, 'production'

# Unicorn の設定 see: https://github.com/tablexi/capistrano3-unicorn
# http://stackoverflow.com/questions/20789080/capistrano-3-wrong-path-in-the-shared-path-variable
# set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"
set :unicorn_pid, -> { "#{shared_path}/tmp/pids/unicorn.pid" }

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :mkdir, '-p'. release_path.join('tmp')
      execute :touch, release_path.join('tmp/restart.txt')
      invoke 'unicorn:restart'
    end
  end

  desc 'upload important files'
  task :upload do
    on roles(:app) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      upload!('config/database.yml', "#{shared_path}/config/database.yml")
      upload!('config/secrets.yml', "#{shared_path}/config/secrets.yml")
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        execute :rm, '-rf', release_path.join('tmp/cache')
      end
    end
  end

  before :started, 'deploy:upload'
  after :finishing, 'deploy:cleanup'
end
