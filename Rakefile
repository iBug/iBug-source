require 'rake/clean'

CLEAN.include '.jekyll-cache', '.sass-cache', '.git-metadata'

task default: %w[clean build]

task :build do |t, args|
  cmd = %w[bundle exec jekyll build]
  cmd << '--profile' if ENV['CI']
  cmd << '--trace'
  cmd << '--lsi' if ENV['LSI']
  cmd << '--watch' if args.extras.include? 'watch'
  cmd.concat(%w[--config _config.yml,_local.yml]) if File.file? '_local.yml'
  begin
    sh(*cmd)
  rescue Interrupt
  end
end

task :watch do
  ENV['JEKYLL_ENV'] ||= 'development'
  Rake::Task[:build].invoke('watch')
end

task :serve, %i[port] do |t, args|
  cmd = %w[bundle exec jekyll serve]
  cmd.concat(['--port', args.port]) unless args.port.nil?
  cmd.concat(%w[--config _config.yml,_local.yml]) if File.file? '_local.yml'
  begin
    ENV['JEKYLL_ENV'] = 'development'
    sh(*cmd)
  rescue Interrupt
  end
end
