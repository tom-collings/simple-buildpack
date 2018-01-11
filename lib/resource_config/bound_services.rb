require 'util/services'
require 'rexml/document'
require 'rexml/formatters/pretty'
require 'rexml/formatters/transitive'
require 'json'
require 'pathname'

module ResourceConfig

  class BoundService

    class << self

      attr_reader :environment
      attr_reader :services

      CRED_PARAM_FLAG = 'includeInResources'

      def initialize(app_dir)
        @app_dir = Pathname.new(File.expand_path(app_dir))
        @environment = ENV.to_hash
        @services    = Util::Services.new(parse(@environment.delete('VCAP_SERVICES')))
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

            web_inf = File.join(@app_dir, '/WEB-INF')
            if !Dir.exist?(web_inf) do
                Dir.mkdir(web_inf)
              end
            end

            document = read_xml resources_xml

            resources  = REXML::XPath.match(document, '/resources').first
            resources  = document.add_element 'resources' if resources.nil?

            services_as_resources resources

            write_xml resources_xml, document

          end
        end

        def services_as_resources(resources)
          @services.each do |service|
            next unless (service['credentials'].include? CRED_PARAM_FLAG) && (service['credentials'][CRED_PARAM_FLAG] == 'true')
            add_resource service, resources
          end
        end

        def add_resource(service, resources)

          attributeArray = ['id', 'type', 'class-name', 'provider', 'factory-name', 'properties-provider', 'classpath', 'aliases', 'post-construct', 'pre-destroy', 'Lazy']

          credsHash = Hash[service['credentials'].map {|key, value| [key, value]} ]

          # split the hash into two pieces:  one where they should be included as attributes
          # and one where they should be included as properties
          credsAsAttributes = credsHash.select{|x| attributeArray.include? x}
          credsAsProperties = credsHash.select{|x| !attributeArray.include? x}

          # remove the flag param as a property
          credsAsProperties = credsAsProperties.select{|x| (x != CRED_PARAM_FLAG)  }

          resource = resources.add_element 'Resource', credsAsAttributes

          credsAsProperties.each do |key, value|

            resource.add_text REXML::Text.new((key + " = " + value + "\n"), true)

          end

        end



      def parse(input)
          input ? JSON.parse(input) : {}
      end

      def resources_xml
          @app_dir+ 'WEB-INF/resources.xml'
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

      def with_timing(caption)
        start_time = Time.now
        print "       #{caption} "

        yield

        puts "(#{(Time.now - start_time)})"
      end

      def formatter
        formatter         = REXML::Formatters::Transitive.new(4)
        formatter
      end

    end

  end

end
