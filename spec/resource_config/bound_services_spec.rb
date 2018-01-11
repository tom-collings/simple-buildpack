require 'spec_helper'
require 'tmpdir'
#require 'component_helper'
require 'resource_config/bound_services'

describe ResourceConfig::BoundService do


  let(:component) { described_class.new }

  let(:configuration) { {} }

  let(:context) do
    {
      component_name: described_class.to_s.split('::').last,
      configuration:  configuration
     }
  end

  previous_environment = ENV.to_hash

  let(:environment) do
    { 'VCAP_SERVICES' => vcap_services.to_json }
  end

  before do
    ENV.update environment
  end

  after do
    ENV.replace previous_environment
  end

  context do
    let(:vcap_services) do
      {
        'simple-want-a-resource' => [{ 'name'        => 'my_service',
                                              'tags'        => [],
                                              'credentials' => {
                                                'includeInResources': 'true'
                                              } }]
      }
    end

    it 'creates a simple resource file with one resource node' do

      app_dir = Pathname.new Dir.mktmpdir

      web_inf = app_dir + 'WEB-INF'

      Dir.mkdir web_inf

      ResourceConfig::BoundService.with_buildpack(app_dir)

      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      expect(resources_xml.read).to match(%r{<Resource\s*\/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'simple-dont-want-a-resource' => [{ 'name'        => 'my_service',
                                              'tags'        => [],
                                              'credentials' => {
                                                'includeInResources': 'false'
                                              } }]
      }
    end

    it 'creates a simple resource file with no nodes' do

      app_dir = Pathname.new Dir.mktmpdir

      web_inf = app_dir + 'WEB-INF'

      Dir.mkdir web_inf

      ResourceConfig::BoundService.with_buildpack(app_dir)

      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      expect(resources_xml.read).to match(%r{<resources\s*\/>})
    end

  end

  context do
    let(:vcap_services) do
      {
        'want-a-resource-with-attrs-and-props' => [{ 'name'        => 'my_service',
                                              'tags'        => [],
                                              'credentials' => {
                                                'includeInResources': 'true',
                                                'id': 'myId',
                                                'class-name': 'my.org.package.class',
                                                'name1': 'val1',
                                                'name2': 'val2'
                                              } }]
      }
    end

    it 'creates a resource file with one node and attrs and props populated' do

      app_dir = Pathname.new Dir.mktmpdir

      web_inf = app_dir + 'WEB-INF'

      Dir.mkdir web_inf

      ResourceConfig::BoundService.with_buildpack(app_dir)

      resources_xml = web_inf + 'resources.xml'
      expect(resources_xml).to exist

      expect(resources_xml.read).to match(%r{<Resource id='myId' class-name='my.org.package.class'\s*>name1 = val1\s*name2 = val2\s*</Resource\s*>})
    end

  end

end
