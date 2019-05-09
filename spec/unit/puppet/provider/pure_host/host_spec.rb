require 'spec_helper'

describe Puppet::Type.type(:pure_host).provider(:host) do

  before :each do
    allow(Puppet::Type.type(:pure_host)).to receive(:defaultprovider).and_return described_class
    @device = double(:device)
  end

  let :resource do
    Puppet::Type.type(:pure_host).new(
        :name   => 'pure_host',
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name           => 'pure_host'
    )
  end

  describe 'when asking exists?' do
    it 'should return true if resource is present' do
      resource.provider.set(:ensure => :present)
      expect(resource.provider).to be_exists
    end
    it 'should return false if resource is absent' do
      resource.provider.set(:ensure => :absent)
      expect(resource.provider).to_not be_exists
    end
  end

  describe '#instances' do
    it 'should return an array of current hosts' do
      allow_any_instance_of(Purest::Host).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('host-list.json')), symbolize_names: true)}

      instances = described_class.instances
      expect(instances.size).to eq(1)

      expect(instances.map do |prov|
        {
            :name    => prov.get(:name),
            :ensure  => prov.get(:ensure),
            :iqnlist => prov.get(:iqnlist),
            :wwnlist => prov.get(:wwnlist),
        }
      end).to eq([
          {
              :name    => 'host01',
              :ensure  => resource[:ensure],
              :iqnlist => ['123456'],
              :wwnlist => ['51402EC0017AA6B4']
          }
      ])
    end
  end

  describe '#prefetch' do
    it 'exists' do
      allow_any_instance_of(Purest::Host).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('host-list.json')), symbolize_names: true)}

      current_provider = resource.provider
      resources        = {'name' => resource}
      described_class.prefetch(resources)
      expect(resources['name']).not_to be(current_provider)
    end
  end

  describe 'when creating a host' do
    it 'should be able to create it' do
      expect_any_instance_of(Purest::Host).to receive(:create).with(name: 'pure_host', iqnlist: nil, wwnlist: nil)
      resource.provider.create
    end
  end

  describe 'when destroying a volume' do
    it 'should be able to delete it' do
      expect_any_instance_of(Purest::Host).to receive(:delete).with(name: 'pure_host')
      resource.provider.destroy
    end
  end

  describe 'when modifying a host' do
    before(:each) {
      resource.provider.set(name: 'pure_host')
    }

    describe 'for iqnlist' do
      it "should be able to update iqnlist" do
        expect_any_instance_of(Purest::Host).to receive(:update).with(name: 'pure_host', iqnlist: ["123456"])
        resource[:iqnlist] = ['123456']
        resource.provider.send("iqnlist=", ['123456'])
      end
    end

    describe 'for wwnlist' do
      it "should be able to update wwnlist" do
        expect_any_instance_of(Purest::Host).to receive(:update).with(name: 'pure_host', wwnlist: ["abcdef"])
        resource[:wwnlist] = ['abcdef']
        resource.provider.send("wwnlist=", ['abcdef'])
      end
    end
  end
end
