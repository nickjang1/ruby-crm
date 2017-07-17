class Tempfile
  def self.new_from_url(url)
    require 'open-uri'

    extname = File.extname(url)
    basename = File.basename(url, extname)

    file = Tempfile.new([basename, extname])
    file.binmode
    URI.parse(url).open {|data| file.write data.read}
    file.rewind
 
    file
  end
end
