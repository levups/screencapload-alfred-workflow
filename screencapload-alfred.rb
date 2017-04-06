# Code adapted from the screencapload project
# https://github.com/czj/screencapload
#
# imgur API key used here will probably be used more than 100 times / hour
# so we'll need to request another one, or unlimited access.

config_file = "#{ENV['HOME']}/.imgur"
tempfile = "/tmp/screenshot-#{Time.now.to_f}.png"
trimmed_tempfile = "#{tempfile}-trimmed.png"

api_key = if File.exists?(config_file)
  File.read(config_file).strip
else
  '5d900ac2731b5fb'
end

# Take a screenshot on OSX
`/usr/sbin/screencapture -x -i '#{tempfile}'`

# Check that the screenshot was actually captured, exit if not
unless File.exists?(tempfile)
  exit! 1
end

# Trim the image
if File.exists?(gm = "/usr/local/bin/gm")
  `#{gm} convert "#{tempfile}" -trim "#{trimmed_tempfile}" && mv "#{trimmed_tempfile}" "#{tempfile}"`
end

# Recompress PNG color depth for faster upload/download
if File.exist?(pngquant = "/usr/local/bin/pngquant")
  `#{pngquant} --force --skip-if-larger --ext ".png" "#{tempfile}"`
end

# Recompress PNG for faster upload/download
if File.exists?(optipng = "/usr/local/bin/optipng")
  `#{optipng} "#{tempfile}"`
end

# Upload to imgur
response = `curl --header 'Authorization: Client-ID #{api_key}' --silent -X POST -F 'image=@#{tempfile}' 'https://api.imgur.com/3/upload.xml'`

# Remove tempfile
`rm #{tempfile}`

# Parse response and get original image url from XML
require "rexml/document"
url = REXML::Document.new(response).root.elements['link'].text

# Alfred will copy the URL to the clipboard and paste it to frontmost app
print url
