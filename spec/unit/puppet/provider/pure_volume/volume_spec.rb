require 'spec_helper'

describe Puppet::Type.type(:pure_volume).provider(:volume) do

  before :each do
    allow(Puppet::Type.type(:pure_volume)).to receive(:defaultprovider).and_return described_class
    @device    = double(:device)
  end

  let :resource do
    Puppet::Type.type(:pure_volume).new(
      :name   => 'pure_vol',
      :ensure => :present,
      :size   => '10G'
    )
  end

  let :provider do
    described_class.new(
      :name => 'pure_vol'
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
    it 'should return an array of current volumes' do
      allow_any_instance_of(Purest::Volume).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('volume-list.json')), symbolize_names: true)}

      instances = described_class.instances
      expect(instances.size).to eq(2)

      expect(instances.map do |prov|
        {
          :name   => prov.get(:name),
          :ensure => prov.get(:ensure),
          :size   => prov.get(:size)
        }
      end).to eq([
        {
          :name   => 'vol1',
          :ensure => resource[:ensure],
          :size   => '30G'
        },
        {
          :name   => 'vol2',
          :ensure => resource[:ensure],
          :size   => '14T'
        }
      ])
    end
  end

  describe '#prefetch' do
    it 'exists' do
      allow_any_instance_of(Purest::Volume).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('volume-list.json')), symbolize_names: true)}

      current_provider = resource.provider
      resources = { 'volume-name' => resource }
      described_class.prefetch(resources)
      expect(resources['volume-name']).not_to be(current_provider)
    end
  end

  describe 'when creating a volume' do
    it 'should be able to create it' do
      expect_any_instance_of(Purest::Volume).to receive(:create).with(name: 'pure_vol', size: '10G')
      resource.provider.create
    end
  end

  describe 'when destroying a volume' do
    it 'should be able to delete it' do
      expect_any_instance_of(Purest::Volume).to receive(:delete).with(name: 'pure_vol')
      resource.provider.destroy
    end
  end

  describe 'when modifying a volume' do
    before(:each) {
      resource.provider.set(name: 'pure_vol')
    }

    describe 'for #size=' do
      it "should be able to increase a volume size" do
        expect_any_instance_of(Purest::Volume).to receive(:update).with(name: 'pure_vol', size: '2T')
        resource[:size] = '2T'
        resource.provider.send("size=", '2T')
      end
    end
  end
end
