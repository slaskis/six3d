class ConvertController < ApplicationController
    
  def index
  end
  
  def upload
    font = Font.new
    font.file = params["Font"]["file"]
    font.save!
    font.save! ## save again for filepath to set
    @id = font.id
  end

  # TODO Error checking on FAR compression
  # TODO Get FAR to work on dreamhost
  # TODO Filenames should be formatted like: comic-sans.svg, not Comic Sans MS.svg, i.e. lowercase, a-z 0-9, and with dashes instead of spaces
  def convert
    font = Font.find( params[:id] )    
    filename = File.basename( font.filepath , ".ttf" ).downcase.sub( " " , "-" )
    bin_dir = RAILS_ROOT + "/bin"
    output_dir = RAILS_ROOT + "/public/output"
    svg = `java -jar #{bin_dir}/batik-ttf2svg.jar #{font.filepath}`
    @svg = "#{output_dir}/#{filename}.svg"
    @far = "#{output_dir}/#{filename}.far"
    if( svg[0,5] == "<?xml" ) # make sure the conversion didn't fail
      # create dirs
      Dir.mkdir(File.dirname(@svg)) if !File.exists?(File.dirname(@svg)) 
      # write svg to file
      File.open(@svg, "wb") { |f| f << svg } 
      # compress to far
      far = `#{bin_dir}/far #{@far} #{@svg}`
      if File.exists?(@far)
        @svg = "/output/#{filename}.svg"
        @far = "/output/#{filename}.far"
        flash[:notice] = "Successfully converted"
      else
        flash[:notice] = "There was an error while compressing: " + far
      end
    else
      flash[:notice] = "There was an error while converting: " + svg
    end
  end
end
