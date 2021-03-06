namespace :aspace do
  namespace :process do
    desc "Analyze all finding aids in directory with current schematron"
    task :analyze => :environment do
      raise "EADS environment variable must be set to directory with input EADs" unless ENV['EADS']
      run = Run.create(name: ENV.fetch('NAME', File.basename(ENV['EADS'])),
                       schematron: Schematron.current,
                       data: {
                         path: File.expand_path(ENV['EADS']),
                         method: 'rake'
                       })
      run.perform_analysis(
        Dir[File.join(File.expand_path(ENV['EADS']), "*.xml")].map do |f|
          FindingAidVersion.find_or_create_by(digest: FindingAidFile.new(IO.read(f)).digest)
        end
      )
    end

    task :analyze_and_fix => :environment do
      unless ENV['EADS'] && File.directory?(File.expand_path(ENV['EADS']))
        raise "EADS environment variable must be set to directory with input EADS"
      end
      run = Run.create(name: ENV.fetch('NAME', File.basename(ENV['EADS'])), schematron: Schematron.current)
      run.perform_processing_run(
        Dir[File.join(File.expand_path(ENV['EADS']), "*.xml")].map do |f|
          FindingAidVersion.find_or_create_by(digest: FindingAidFile.new(IO.read(f)).digest)
        end
      )
    end
  end
end
