class Font < ActiveRecord::Base
  def file=(uploaded_file)  
    @uploaded_file = uploaded_file
    @filename = sanitize_filename(@uploaded_file.original_filename)
    write_attribute("content_type", @uploaded_file.content_type)
  end
  
  def after_create
    if !File.exists?(File.dirname(path_to_file))
      Dir.mkdir(File.dirname(path_to_file))
    end
    if @uploaded_file.instance_of?(Tempfile)
      FileUtils.copy(@uploaded_file.local_path, path_to_file)
    else
      File.open(self.path_to_file, "wb") { |f| f.write(@uploaded_file.read) }
    end
    write_attribute("filepath", path_to_file)
  end

  def after_destroy
    if File.exists?(self.file)
      File.delete(self.file)
      Dir.rmdir(File.dirname(self.file))
    end
  end
  
  def path_to_file
    File.expand_path("#{RAILS_ROOT}/tmp/upload/#{self.id}/#{@filename}")
  end
  
  private
  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name) 
    # replace all none alphanumeric, underscore or perioids with underscore
    just_filename.gsub(/[^\w\.\_]/,'_') 
  end
end

