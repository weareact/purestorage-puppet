require 'spec_helper'
require 'puppet/util/network_device'
require 'puppet/util/network_device/pure/device'
require 'json'

describe Puppet::Util::NetworkDevice::Pure::Facts do

  before(:each) do
    @fact_class = Puppet::Util::NetworkDevice::Pure::Facts.new
  end

  it 'should have facts read-only' do
    expect(@fact_class.facts).to be_nil
    expect {@fact_class.facts = 'some new facts'}.to raise_error NoMethodError
  end

  context '#retrieve' do
    let(:array_response) {
      JSON.parse('{
        "array_name": "Pure01",
        "id": "de2d6151-ba43-4264-9e6f-430626c2959e",
        "revision": "201802091837+238a5fe",
        "version": "4.10.9"
      }', symbolize_names: true)
    }

    let(:controller_response) {
      JSON.parse('[
        {
          "status": "ready",
          "model": "FA-m10r2",
          "version": "4.10.9",
          "name": "CT0",
          "mode": "secondary"
        },
        {
          "status": "ready",
          "model": "FA-m10r2",
          "version": "4.10.9",
          "name": "CT1",
          "mode": "primary"
        }
      ]', symbolize_names: true)
    }

    let(:connection_response) {
      JSON.parse('[
        {
          "vol": "volume_1",
          "name": "host_1",
          "lun": 1
        },
        {
          "vol": "volume_2",
          "name": "host_1",
          "lun": 2
        },
        {
          "vol": "volume_3",
          "name": "host_2",
          "lun": 1
        },
        {
          "vol": "volume_4",
          "name": "host_2",
          "lun": 2
        }
      ]', symbolize_names: true)
    }

    it "should get facts from array" do
      allow_any_instance_of(Purest::PhysicalArray).to receive(:get).with(no_args).and_return(array_response)
      allow_any_instance_of(Purest::PhysicalArray).to receive(:get).with(controllers: true).and_return(controller_response)
      allow_any_instance_of(Purest::Host).to receive(:get).with(connect: true).and_return(connection_response)

      facts = @fact_class.retrieve
      expect(facts).to eq({
          :pure_storage => {
              :vendor_id   => "pure",
              :array_name  => "Pure01",
              :version     => "4.10.9",
              :controllers => {
                  :CT0 => [{
                      :status  => "ready",
                      :model   => "FA-m10r2",
                      :version => "4.10.9",
                      :mode    => "secondary"
                  }],
                  :CT1 => [{
                      :status  => "ready",
                      :model   => "FA-m10r2",
                      :version => "4.10.9",
                      :mode    => "primary"
                  }],
              },
              :connections => {
                  :host_1 => [
                      {
                          :vol => "volume_1",
                          :lun => 1
                      },
                      {
                          :vol => "volume_2",
                          :lun => 2
                      },
                  ],
                  :host_2 => [
                      {
                          :vol => "volume_3",
                          :lun => 1
                      },
                      {
                          :vol => "volume_4",
                          :lun => 2
                      }
                  ]
              }
          }
      })
    end
  end
end
