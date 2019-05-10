require 'spec_helper'

describe Puppet::Type.type(:pure_protection_group).provider(:protection_group) do

  before :each do
    allow(Puppet::Type.type(:pure_protection_group)).to receive(:defaultprovider).and_return described_class
    @device = double(:device)
  end

  let :resource do
    Puppet::Type.type(:pure_protection_group).new(
        :name   => 'pg01',
        :ensure => :present,
        :hosts => ["host01"],
        :targets => ["target01"],
        :volumes => ["volume01"]
    )
  end

  let :provider do
    described_class.new(
        :name           => 'pg01'
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
    it 'should return an array of current protection groups' do
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('protection-group-list.json')), symbolize_names: true)}
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(schedule: true) {JSON.parse(File.read(my_fixture('protection-group-schedule-list.json')), symbolize_names: true)}
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(retention: true) {JSON.parse(File.read(my_fixture('protection-group-retention-list.json')), symbolize_names: true)}

      instances = described_class.instances
      expect(instances.size).to eq(1)

      expect(instances.map do |prov|
        {
            :name    => prov.get(:name),
            :ensure  => prov.get(:ensure),
            :hosts => prov.get(:hosts),
            :targets => prov.get(:targets),
            :volumes => prov.get(:volumes),
            :snapshot_enabled => prov.get(:snapshot_enabled),
            :snapshot_frequency_unit => prov.get(:snapshot_frequency_unit),
            :snapshot_frequency_amount => prov.get(:snapshot_frequency_amount),
            :snapshot_at => prov.get(:snapshot_at),
            :snapshot_retention_unit => prov.get(:snapshot_retention_unit),
            :snapshot_retention_amount => prov.get(:snapshot_retention_amount),
            :snapshot_per_day => prov.get(:snapshot_per_day),
            :snapshot_for_days => prov.get(:snapshot_for_days)
        }
      end).to eq([
          {
              :name                => 'pg01',
              :ensure              => resource[:ensure],
              :hosts               => ["host01"],
              :targets             => ["target01"],
              :volumes             => ["volume01"],
              :snapshot_enabled        => "true",
              :snapshot_frequency_unit      => "hours",
              :snapshot_frequency_amount    => 1,
              :snapshot_at => 0,
              :snapshot_retention_unit => "hours",
              :snapshot_retention_amount => 3,
              :snapshot_per_day => 1,
              :snapshot_for_days => 1
          }
      ])
    end
  end

  describe '#prefetch' do
    it 'exists' do
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(no_args) {JSON.parse(File.read(my_fixture('protection-group-list.json')), symbolize_names: true)}
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(schedule: true) {JSON.parse(File.read(my_fixture('protection-group-schedule-list.json')), symbolize_names: true)}
      allow_any_instance_of(Purest::ProtectionGroup).to receive(:get).with(retention: true) {JSON.parse(File.read(my_fixture('protection-group-retention-list.json')), symbolize_names: true)}

      current_provider = resource.provider
      resources        = {:name => resource}
      described_class.prefetch(resources)
      expect(resources['name']).not_to be(current_provider)
    end
  end

  describe 'when creating a protection group' do
    it 'should be able to create it' do
      expect_any_instance_of(Purest::ProtectionGroup).to receive(:create).with(name: 'pg01', hostlist: ["host01"], targetlist: ["target01"], vollist: ["volume01"])
      resource.provider.create
    end
  end

  describe 'when destroying a protection group' do
    it 'should be able to delete it' do
      expect_any_instance_of(Purest::ProtectionGroup).to receive(:delete).with(name: 'pg01')
      resource.provider.destroy
    end
  end

  describe 'when modifying a protection group' do
    before(:each) {
      resource.provider.set(name: 'pg01')
    }

    describe 'for hosts' do
      it "should be able to update hosts" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', hostlist: %w(host01 host02))
        resource[:hosts] = %w(host01 host02)
        resource.provider.send("hosts=", %w(host01 host02))
      end
    end

    describe 'for targets' do
      it "should be able to update targets" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', targetlist: %w(target01 target02))
        resource[:targets] = %w(target01 target02)
        resource.provider.send("targets=", %w(target01 target02))
      end
    end

    describe 'for volumes' do
      it "should be able to update volumes" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', vollist: %w(volume01 volume02))
        resource[:volumes] = %w(volume01 volume02)
        resource.provider.send("volumes=", %w(volume01 volume02))
      end
    end

    describe 'for snapshot_enabled' do
      it "should be able to update snapshot_enabled" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', snap_enabled: :true)
        resource[:snapshot_enabled] = true
        resource.provider.send("snapshot_enabled=", true)
      end
    end

    describe 'for snapshot_frequency' do
      before(:each) {
        resource.provider.set(snapshot_frequency_unit: 'hours')
        resource.provider.set(snapshot_frequency_amount: 5)
      }

      it "should be able to update snapshot_frequency_unit" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', snap_frequency: 5 * 60 * 60 * 24)
        resource[:snapshot_frequency_unit] = 'days'
        resource.provider.send("snapshot_frequency_unit=", 'days')
      end

      it "should be able to update snapshot_frequency_amount" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', snap_frequency: 3 * 60 * 60)
        resource[:snapshot_frequency_amount] = 3
        resource.provider.send("snapshot_frequency_amount=", 3)
      end
    end

    describe 'for snapshot_at' do
      it "should be able to update snapshot_at" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', snap_at: 16 * 60 * 60)
        resource[:snapshot_at] = 16
        resource.provider.send("snapshot_at=", 16)
      end
    end

    describe 'for snapshot_retention' do
      before(:each) {
        resource.provider.set(snapshot_retention_unit: 'hours')
        resource.provider.set(snapshot_retention_amount: 5)
      }

      it "should be able to update snapshot_retention_unit" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', all_for: 5 * 60 * 60 * 24)
        resource[:snapshot_retention_unit] = 'days'
        resource.provider.send("snapshot_retention_unit=", 'days')
      end

      it "should be able to update snapshot_retention_amount" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', all_for: 3 * 60 * 60)
        resource[:snapshot_retention_amount] = 3
        resource.provider.send("snapshot_retention_amount=", 3)
      end
    end

    describe 'for snapshot_per_day' do
      it "should be able to update snapshot_per_day" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', per_day: 5)
        resource[:snapshot_per_day] = 5
        resource.provider.send("snapshot_per_day=", 5)
      end
    end

    describe 'for snapshot_for_days' do
      it "should be able to update snapshot_for_days" do
        expect_any_instance_of(Purest::ProtectionGroup).to receive(:update).with(name: 'pg01', days: 5)
        resource[:snapshot_for_days] = 5
        resource.provider.send("snapshot_for_days=", 5)
      end
    end

  end
end
