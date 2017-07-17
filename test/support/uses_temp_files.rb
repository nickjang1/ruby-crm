module UsesTempFiles
  
  def self.included(example_group)
    example_group.extend(self)
  end
  
  def in_directory_with_file(file)
    before do
      @pwd = Dir.pwd
      @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
      FileUtils.mkdir_p(@tmp_dir)
      Dir.chdir(@tmp_dir)
      
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)
    end
    
    define_method(:content_for_file) do |content|
      f = File.new(File.join(@tmp_dir, file), 'a+')
      f.write(content)
      f.flush
      f.close
    end
    
    def uploaded_file_object(klass, attribute, file, content_type = 'text/plain')
      filename = File.basename(file.path)
      klass_label = klass.to_s.underscore

      ActionDispatch::Http::UploadedFile.new(
        tempfile: file,
        filename: filename,
        head: %Q{Content-Disposition: form-data; name="#{klass_label}[#{attribute}]"; filename="#{filename}"},
        content_type: content_type
      )
    end
    
    after do
      Dir.chdir(@pwd)
      FileUtils.rm_rf(@tmp_dir)
    end
  end
  
end