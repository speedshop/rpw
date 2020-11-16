require "fileutils"
require "yaml"

module RPW
  class ClientData
    DOTFILE_NAME = ".rpw_info"

    def initialize
      data # access file to load
    end

    def [](key)
      data[key]
    end

    def []=(key, value)
      data
      data[key] = value

      begin
        File.open(filestore_location, "w") { |f| f.write(YAML.dump(data)) }
      rescue
        raise Error, "The RPW data at #{filestore_location} is not writable. \
                      Check your file permissions."
      end
    end

    def self.create_in_pwd!
      FileUtils.touch(File.expand_path("./" + DOTFILE_NAME))
    end

    def self.create_in_home!
      unless File.directory?(File.expand_path("~/.rpw/"))
        FileUtils.mkdir(File.expand_path("~/.rpw/"))
      end

      FileUtils.touch(File.expand_path("~/.rpw/" + DOTFILE_NAME))
    end

    def self.delete_filestore
      return unless File.exist?(filestore_location)
      FileUtils.remove(filestore_location)
    end

    def self.exists?
      File.exist? filestore_location
    end

    def self.filestore_location
      if File.exist?(File.expand_path("./" + DOTFILE_NAME))
        File.expand_path("./" + DOTFILE_NAME)
      else
        File.expand_path("~/.rpw/" + DOTFILE_NAME)
      end
    end

    private

    def filestore_location
      self.class.filestore_location
    end

    def data
      @data ||= begin
        yaml = YAML.safe_load(File.read(filestore_location), permitted_classes: [Time])
        yaml || {}
      end
    end
  end
end
