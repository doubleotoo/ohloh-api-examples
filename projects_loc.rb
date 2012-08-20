#!/usr/bin/env ruby
require 'net/http'
require 'rexml/document'

# total_code_lines

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
  STDERR.puts "Usage: #{__FILE__} [api_key]"
  exit 1
end

$api_key = ARGV[0]

def get_all_projects
  #
  # Connect to the Ohloh website and retrieve the account data.
  #
  http = Net::HTTP.new('www.ohloh.net', 80).start do |session|

    page = 1
    while page >= 1 # loops back to first page at end
      response, data = session.get("/projects.xml?v=1&api_key=#{$api_key}&query=c&page=#{page}", nil)

      # HTTP OK?
      if response.code != '200'
        STDERR.puts "#{response.code} - #{response.message}"
        exit 1
      end

      # Parse the response into a structured XML object
      xml = REXML::Document.new(data)
      xml.each_element_with_text do |element|
        if element.name == "first_item_position"
          if element.text == "0" and page > 1 # looped back
            puts "Analyzed #{page - 1} pages"
            exit 0 # done
          end
          break
        end
      end

      # Did Ohloh return an error?
      error = xml.root.get_elements('/response/error').first
      if error
        STDERR.puts "#{error.text}"
        exit 1
      end

      # Output all the immediate child properties of an Account
      # parent.each_child{ |child| # Do something with child }
      xml.root.get_elements('/response/result/project').each do |project|
        project_id = project_name = nil
        project.each_element_with_text do |element|
          project_id    = element.text    if element.name == "id"
          project_name  = element.text    if element.name == "name"
        end
        print "#{project_id} #{project_name} "
        get_loc(project_id)
      end
      page += 1
    end
  end
end

def get_loc(project_id)
  #
  # Connect to the Ohloh website and retrieve the account data.
  #
  http = Net::HTTP.new('www.ohloh.net', 80).start do |session|

    response, data = session.get("/projects/#{project_id}/analyses/latest.xml?v=1&api_key=#{$api_key}", nil)

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
      puts element.text if element.name == "total_code_lines"
    end
  end
end

get_all_projects
