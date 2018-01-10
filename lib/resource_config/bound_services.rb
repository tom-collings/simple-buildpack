require 'util/services'
require 'rexml/document'
require 'rexml/formatters/pretty'
require 'json'
require 'pathname'

module ResourceConfig

  class BoundService

    class << self

      attr_reader :environment
      attr_reader :services

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
          with_timing 'Modifying /WEB-INF/resourcesXYZ.xml for Resource Configuration' do
            document = read_xml resources_xml

            resources  = REXML::XPath.match(document, '/resources').first
            resources  = document.add_element 'resources' if resources.nil?

            services_as_resources resources

            write_xml resources_xml, document

          end
        end

        def services_as_resources(resources)
          @services.each do |service|
            next unless service['includeInResources'].include? 'true'
            add_resource service, resources
          end
        end

        def add_resource(service, resources)
          resources.add_element 'Resource',
                                'id' => "jdbc/#{service['name']}",
                                'type' => 'DataSource',
                                'properties-provider' =>
                                'org.cloudfoundry.reconfiguration.tomee.DelegatingPropertiesProvider'
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

      def with_timing(caption)
        start_time = Time.now
        print "       #{caption} "

        yield

        puts "(#{(Time.now - start_time)})"
      end

      def formatter
        formatter         = REXML::Formatters::Pretty.new(4)
        formatter.compact = true
        formatter
      end

    end

  end

end
