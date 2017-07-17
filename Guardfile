guard 'livereload' do
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|sass|scss|coffee|js|html))).*}) { |m| "/assets/#{m[3]}" }
end

guard 'minitest' do
  # Minitest
  watch(%r{^test/(.*)\/?test_(.*)\.rb})
  watch(%r{^test/(.*)\/(.*)_test\.rb})
  watch(%r{^test/test_helper\.rb}) { "test" }
  watch(%r{^test/factories\.rb}) { "test" }

  # Rails 3.2
  watch(%r{^app\/controllers\/(.*)_controller\.rb}) { |m| "test/integration/#{m[1]}_test.rb" }
  watch(%r{^app\/controllers\/(.*)\/.*_controller\.rb}) { |m| "test/integration/#{m[1]}_test.rb" }
  watch(%r{^app/models/(.*)\.rb}) { |m| "test/models/#{m[1]}_test.rb" }  
  watch(%r{^app/helpers/(.*)\.rb}) { |m| "test/helpers/#{m[1]}_test.rb" }
  watch(%r{^app\/views\/([^\/]*)\/.*\..*\.[erb|haml]}) { |m| "test/integration/#{m[1]}_test.rb" }
end
