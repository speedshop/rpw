require "excon"
require "json"

module RPW
  class Gateway
    attr_accessor :domain

    def initialize(domain, key)
      @domain = domain
      @key = key
    end

    class Error < StandardError; end

    def authenticate_key(key)
      Excon.get(domain + "/license", user: key).status == 200
    end

    def get_content_by_position(position)
      response = Excon.get(domain + "/contents/positional?position=#{position}", user: @key)
      if response.status == 200
        JSON.parse(response.body)
      else
        puts response.inspect
        raise Error, "There was a problem fetching this content."
      end
    end

    def list_content
      response = Excon.get(domain + "/contents", user: @key)
      if response.status == 200
        JSON.parse(response.body)
      else
        puts response.inspect
        raise Error, "There was a problem fetching this content."
      end
    end

    def download_content(content, folder:)
      puts "Downloading #{content["title"]}..."
      downloaded_file = File.open("#{folder}/#{content["s3_key"]}.partial", "w")
      streamer = lambda do |chunk, remaining_bytes, total_bytes|
        downloaded_file.write(chunk)
        print 13.chr
        print "Remaining: #{(remaining_bytes.to_f / total_bytes * 100).round(2).to_s.rjust(8)}%" if remaining_bytes
      end
      response = Excon.get(content["url"], response_block: streamer)
      unless response.status == 200
        puts response.inspect
        raise Error.new("Server problem: #{response.status}")
      end
      downloaded_file.close
      print "\n"
      File.rename(downloaded_file, "#{folder}/#{content["s3_key"]}")
    end

    def latest_version?
      resp = Excon.get("https://rubygems.org/api/v1/gems/rpw.json")
      data = JSON.parse resp.body
      Gem::Version.new(RPW::VERSION) >= Gem::Version.new(data["version"])
    end

    def register_email(email)
      Excon.put(domain + "/license?email=#{email}&key=#{@key}").status == 200
    end
  end
end
