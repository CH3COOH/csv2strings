# MIT License
#
# Copyright (c) 2023 Kenji Wada
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'csv'
require 'fileutils'


class CSVProcess
  def self.run(input_file_path, output_dir_path)
    unless File.exist?(input_file_path)
      puts "Error! Source file not found."
      return
    end
    Dir.mkdir(output_dir_path) unless Dir.exist?(output_dir_path)
    
    csv_str = File.read(input_file_path)
    csv = CSV.parse(csv_str, headers: true)
    key_id = csv.headers[0]
    
    # generate strings files
    csv.headers[1..-1].each do |header|
      next if header.nil? || header.empty?
      
      puts "header #{header}"
      
      dest_ios = []
      dest_ios << "/* \n  Localizable.strings\n  #{header}\n  \n  Generate by csv2strings\n*/\n"
      dest_android = []
      dest_android << "<!-- Generate by csv2strings -->\n"
      dest_android << "<resources>"
      
      csv.each do |row|
        id = row[key_id]
        next if id.nil? || id.empty?
        
        if id.start_with?("#")
          separator = id.gsub("# ", "").gsub("#", "")
          dest_ios << "\n// MARK: - #{separator}"
          dest_android << "\n    <!-- #{separator} -->"
          next
        end
        
        value = row[header].nil? ? "{{Undefined: #{id}}}" : row[header].gsub("\"", "").strip
        
        ios_value = value.gsub("&amp;", "&").gsub("&nbsp;", " ")
        dest_ios << "\"#{id}\" = \"#{ios_value}\";"
        
        if value.include?("%")
          v = value.gsub("%@", "%s")
          .gsub("%1$@", "%1$s")
          .gsub("%2$@", "%2$s")
          .gsub("%3$@", "%3$s")
          .gsub("%4$@", "%4$s")
          .gsub("'", "\\&apos;")
          .gsub("&nbsp;", " ")
          dest_android << "    <string name=\"#{id}\" formatted=\"true\">#{v}</string>"
        else
          v = value.gsub("'", "\\&apos;")
          .gsub("&nbsp;", " ")
          dest_android << "    <string name=\"#{id}\">#{v}</string>"
        end
      end
      dest_android << "</resources>"
      
      output(output_dir_path, header, dest_ios.join("\n"), "ios", "Localizable.strings")
      output(output_dir_path, header, dest_android.join("\n"), "android", "strings.xml")
    end
    
    # generate infoplist files (iOS only)
    csv.headers[1..-1].each do |header|
      next if header.nil? || header.empty?
      
      puts "header #{header}"
      
      dest_ios = []
      dest_ios << "/* \n  InfoPlist.strings\n  #{header}\n  \n  Generate by csv2strings\n*/\n"
      
      csv.each do |row|
        id = row[key_id]
        next if id.nil? || id.empty?
        
        key = case id
      when "BundleDisplayName" then "CFBundleDisplayName"
      when "PhotoLibraryUsageDescription" then "NSPhotoLibraryUsageDescription"
      when "PhotoLibraryAddUsageDescription" then "NSPhotoLibraryAddUsageDescription"
      when "CameraUsageDescription" then "NSCameraUsageDescription"
      when "UserTrackingUsageDescription" then "NSUserTrackingUsageDescription"
      when "LocationAlwaysAndWhenInUseUsageDescription" then "NSLocationAlwaysAndWhenInUseUsageDescription"
      when "LocationWhenInUseUsageDescription" then "NSLocationWhenInUseUsageDescription"
      when "FaceIDUsageDescription" then "NSFaceIDUsageDescription"
        # Add other cases...
      else
        next
      end
      
      value = row[header].nil? ? "{{Undefined: #{id}}}" : row[header].gsub("\"", "").strip
      ios_value = value.gsub("&amp;", "&").gsub("&nbsp;", " ")
      dest_ios << "#{key} = \"#{ios_value}\";"
    end
    
    output(output_dir_path, header, dest_ios.join("\n"), "ios", "InfoPlist.strings")
  end
end

def self.output(dir_path, header, text, os, file_name)
  path = File.join(dir_path, os, header)
  FileUtils.mkdir_p(path)
  
  file_path = File.join(path, file_name)
  File.write(file_path, text)
end
end

if ARGV.length < 2
  puts "csv2strings {source path}.csv {output directory path}"
  exit
end

input_path = ARGV[0]
output_dir = ARGV[1]

puts "src: #{input_path}"
puts "dst: #{output_dir}"

CSVProcess.run(input_path, output_dir)
