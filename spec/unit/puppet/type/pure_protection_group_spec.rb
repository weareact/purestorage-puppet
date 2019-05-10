require 'spec_helper'

describe Puppet::Type.type(:pure_protection_group) do
  let(:protection_group) do
    described_class.new(
        :name => 'pg01'
    )
  end

  context 'attributes' do
    [:name, :device_url].each do |parameter|
      describe parameter.to_s do
        it 'has a name attribute' do
          expect(described_class.attrclass(parameter)).not_to be_nil
        end

        it 'is a parameter' do
          expect(described_class.attrtype(parameter)).to eq(:param)
        end
      end
    end

    [:snapshot_enabled, :snapshot_frequency_unit, :snapshot_frequency_amount, :snapshot_at, :snapshot_retention_unit, :snapshot_retention_amount,
        :snapshot_per_day, :snapshot_for_days].each do |property|
      describe property.to_s do
        it 'has a name attribute' do
          expect(described_class.attrclass(property)).not_to be_nil
        end

        it 'is a property' do
          expect(described_class.attrtype(property)).to eq(:property)
        end
      end
    end

    [:hosts, :targets, :volumes].each do |property|
      describe property.to_s do
        it 'has a name attribute' do
          expect(described_class.attrclass(property)).not_to be_nil
        end

        it 'is a property' do
          expect(described_class.attrtype(property)).to eq(:property)
        end

        it 'should support an array value' do
          protection_group[property] = ['abc', 'def']
          expect(protection_group[property]).to eq(['abc', 'def'])
        end

        it "should convert a string value to an array" do
          protection_group[property] = 'abcdef'
          expect(protection_group[property]).to eq(['abcdef'])
        end
      end
    end

    it 'has name as namevar' do
      expect(described_class.key_attributes.sort).to eq([:name])
    end
  end

  context 'when autorequireing resources' do
    describe 'should autorequire pure_host resources' do
      pure_host = Puppet::Type.type(:pure_host).new(
          name:   'host01',
          ensure: :present
      )

      pure_pg = described_class.new(
          name: 'pg01',
          hosts: ['host01']
      )

      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource pure_host
      catalog.add_resource pure_pg
      req = pure_pg.autorequire

      it 'is equal' do
        expect(req.size).to eq(1)
      end
      it 'has matching source' do
        expect(req[0].source).to eq pure_host
      end
      it 'has matching target' do
        expect(req[0].target).to eq pure_pg
      end
    end

    describe 'should autorequire pure_volume resource' do
      pure_volume = Puppet::Type.type(:pure_volume).new(
          name:   'vol01',
          ensure: :present,
          size:   '10G'
      )

      pure_pg = described_class.new(
          name: 'pg01',
          volumes: ['vol01']
      )

      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource pure_volume
      catalog.add_resource pure_pg
      req = pure_pg.autorequire

      it 'is equal' do
        expect(req.size).to eq(1)
      end
      it 'has matching source' do
        expect(req[0].source).to eq pure_volume
      end
      it 'has matching target' do
        expect(req[0].target).to eq pure_pg
      end
    end
  end

end
