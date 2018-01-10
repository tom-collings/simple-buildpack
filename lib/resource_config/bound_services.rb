require 'util/services'
require 'json'

module ResourceConfig

  class BoundService

    attr_reader :environment
    attr_reader :services

    def initialize(app_dir)
      @app_dir = Pathname.new(File.expand_path(app_dir))
      @environment = ENV.to_hash
      @services    = Services.new(parse(@environment.delete('VCAP_SERVICES')))
    end

    def with_buildpack(app_dir)
      initialize(app_dir)
      supply
    end

    def supply
      mutate_resources_xml
    end

    def mutate_resources_xml
        with_timing 'Modifying /WEB-INF/resources.xml for Resource Configuration' do
          document = read_xml resources_xml

          resources  = REXML::XPath.match(document, '/resources').first
          resources  = document.add_element 'resources' if resources.nil?

          write_xml resources_xml, document

        end
      end

    def parse(input)
        input ? JSON.parse(input) : {}
    end

    def resources_xml
        @app_dir+ 'WEB-INF/resourcesXYZ.xml'
    end

    def read_xml(file)
      File.open(file, 'a+') { |f| REXML::Document.new f }
    end

    def write_xml(file, document)
      file.open('w') do |f|
        formatter.write document, f
        f << "\n"
      end
    end

  end

end