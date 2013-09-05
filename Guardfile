# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require 'active_support/core_ext'

guard 'spork', :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch(%r{^app/models/.+\.rb$})
  watch(%r{^app/controllers/.+\.rb$})
  watch('config/application.rb')
  watch('config/environment.rb')
  watch('config/routes.rb')
  watch(%r{^config/environments/.+\.rb$})
  watch(%r{^config/initializers/.+\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb')
  watch('test/test_helper.rb')
  watch('spec/support/')
end

guard 'rspec', :version => 2, :cli => '--drb', :all_on_start => false, :all_after_pass => false do
  watch(%r{^spec/(.+)\.rb$})    { |m| "spec/#{m[1]}\.rb" }

  ## Warning :this will run all requests tests
  watch(%r{^app/(.+)\.rb$})                           { "spec/requests/" }

  # Capybara features specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/features/#{m[1]}_spec.rb" }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
end


