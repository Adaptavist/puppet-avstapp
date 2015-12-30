module Puppet::Parser::Functions
    # Parses version from tarbal provided for all supported products by avst-app
    # Usage: parse_version(product, tarball_filename)
    newfunction(:parse_version, :type => :rvalue) do |args|
        product = args[0]
        filename = args[1]
        early_access = args[2]
        case product
        when "fisheye", "artifactory", "sonarqube"
            # fisheye install file is in format fisheye-<version>.zip
            # artifactory: artifactory-powerpack-standalone-3.2.1.1.zip
            packaging_type = ".zip"
            splitted = filename.split("-")[-1]
        when "coverity"
            # cov-platform-linux64-7.0.3.sh
            splitted = filename.split("-")[-1]
            packaging_type = ".sh"
        else
            product_to_check=product
            # Stash was renamed from version 4.0.0 to bitbucket
            if (filename.include? "atlassian-stash-")
                product_to_check="stash"
            end
            # all other avstapp supported products are in format path/something-<product>-<version>.tar.gz
            if (early_access != nil && early_access)
                # early access are formatted: atlassian-confluence-5.6-m8-cluster.tar.gz
                splitted = filename.split("#{product_to_check}-")[-1].split("-")[0]
            else
                splitted = filename.split("#{product_to_check}-")[-1]
            end
            packaging_type = ".tar.gz"
        end
        splitted.sub(packaging_type, "")
    end
end