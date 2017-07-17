namespace :sb do
  desc 'Runs `rake erd` with desired options'
  task erd: :environment do
    ENV['inheritance'] = 'true'
    ENV['polymorphism'] = 'true'
    ENV['exclude'] = 'TagHierarchy'

    Rake::Task['erd'].invoke

    `open erd.pdf`
  end
end
