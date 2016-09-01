require 'net/http'
require 'json'

module Puppet::Parser::Functions
    # returns download url for passed atlassian product and version, if version is set to "current" returns the latest
    # in case download url not found returns "false"
    newfunction(:find_download_url, :type => :rvalue) do |args|
        
        product = args[0]
        looking_for_version = args[1]    

        file_type = ".tar.gz"
        required_description = nil
        case product
        when "jira"
            product_names = ["jira-software", "jira"]
        when "bitbucket"
            # all versions of stash/bitbucket server are under .../stash.json
            product_names = ["stash"]
        when "fisheye"    
            file_type = ".zip"
            product_names = ["crucible"]
        else
            product_names = [product]
        end

        version_types = ["current", "archived"]
        if looking_for_version == "current"
            version_types = ["current"]
        elsif looking_for_version == "eap"
            version_types = ["eap"]
            if product == "jira"
                required_description = "software"
                product_names = ["jira"]
            end
        end

        found = false
        version_types.each do |version_type|
            next if found
            product_names.each do |product_name| 
                url = "https://my.atlassian.com/download/feeds/#{version_type}/#{product_name}.json" 
                uri = URI(url)
                response = Net::HTTP.get(uri)
                begin
                    # parse urls from json
                    JSON.parse(response.sub("downloads(", "")[0...-1]).each do |entry|
                        next unless entry['zipUrl'] and entry['description'] and entry["version"]
                        next unless entry['zipUrl'].end_with? file_type
                        next if entry['description'].include? "WAR"
                        next if required_description and !entry['description'].downcase.include? required_description
                        if looking_for_version == "current" or looking_for_version == "eap" or entry["version"] == looking_for_version
                            found = entry["zipUrl"] 
                            break
                        end
                    end
                    if found
                        break
                    end
                rescue Exception => e
                    puts "#{url} did not return correct data; #{response.inspect}"
                    puts "Exception thrown #{e.inspect}"
                end
            end
        end
        found.to_s
    end
end
