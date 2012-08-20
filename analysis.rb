#!/usr/bin/env ruby
require 'net/http'
require 'rexml/document'
require 'md5'

# This example retrieves basic analysis information
# and outputs it as simple name: value pairs.
#
# Pass your Ohloh API key as the first parameter to this script.
# Ohloh API keys are free. If you do not have one, you can obtain one
# at the Ohloh website:
#
#     http://www.ohloh.net/api_keys/new
#
# Pass the project id of the project as the second parameter to this script.

unless ARGV[0] =~ /[\w]+/
  STDERR.puts "Usage: #{__FILE__} [api_key] [project_id]"
  exit 1
end

api_key = ARGV[0]
project_id = ARGV[1]

#
# Connect to the Ohloh website and retrieve the account data.
#
http = Net::HTTP.new('www.ohloh.net', 80).start do |session|

  response, data = session.get("/projects/#{project_id}/analyses/latest.xml?v=1&api_key=#{api_key}", nil)

  # HTTP OK?
  if response.code != '200'
    STDERR.puts "#{response.code} - #{response.message}"
    exit 1
  end

  # Parse the response into a structured XML object
  xml = REXML::Document.new(data)

  # Did Ohloh return an error?
  error = xml.root.get_elements('/response/error').first
  if error
    STDERR.puts "#{error.text}"
    exit 1
  end

  # Output all the immediate child properties of an Account
  xml.root.get_elements('/response/result/analysis').first.each_element do |element|
    puts "#{element.name}:\t#{element.text}" unless element.has_elements?
  end
end
