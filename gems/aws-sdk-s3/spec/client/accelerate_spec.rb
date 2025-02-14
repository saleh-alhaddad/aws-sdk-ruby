# frozen_string_literal: true

require_relative '../spec_helper'
require 'stringio'

module Aws
  module S3
    describe Client do
      let(:options) do
        { stub_responses: true, region: 'us-east-1' }
      end

      let(:client) { Client.new(options) }

      let(:accelerated_client) do
        Client.new(
          options.merge(use_accelerate_endpoint: true)
        )
      end

      let(:accel_dualstack_client) do
        Client.new(
          options.merge(
            use_accelerate_endpoint: true,
            use_dualstack_endpoint: true
          )
        )
      end

      context ':use_accelerate_endpoint' do
        it 'defaults to false' do
          client = Client.new(options)
          expect(client.config.use_accelerate_endpoint).to be(false)
          resp = client.put_object(bucket: 'bucket-name', key: 'key')
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3.amazonaws.com/key'
          )
        end

        it 'can be set in the constructor' do
          client = Client.new(options.merge(use_accelerate_endpoint: true))
          expect(client.config.use_accelerate_endpoint).to be(true)
          resp = client.put_object(bucket: 'bucket-name', key: 'key')
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3-accelerate.amazonaws.com/key'
          )
        end

        it 'can be set on the operation' do
          expect(client.config.use_accelerate_endpoint).to be(false)
          resp = client.put_object(
            bucket: 'bucket-name', key: 'key', use_accelerate_endpoint: true
          )
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3-accelerate.amazonaws.com/key'
          )
        end

        it 'can be disabled by the operation' do
          resp = accelerated_client.put_object(
            bucket: 'bucket-name', key: 'key', use_accelerate_endpoint: false
          )
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3.amazonaws.com/key'
          )
        end

        it 'raises when accelerate and endpoint are configured' do
          expect do
            Client.new(
              options.merge(
                use_accelerate_endpoint: true, endpoint: 'https://amazon.com'
              )
            ).put_object(bucket: 'bucket-name', key: 'key')
          end.to raise_error(ArgumentError, /:endpoint/)
        end

        it 'raises when accelerate and use_fips_endpoint are configured' do
          expect do
            Client.new(
              options.merge(
                use_accelerate_endpoint: true, use_fips_endpoint: true
              )
            ).put_object(bucket: 'bucket-name', key: 'key')
          end.to raise_error(ArgumentError, /:use_fips_endpoint/)
        end

        it 'does not apply to #create_bucket' do
          resp = accelerated_client.create_bucket(bucket: 'bucket-name')
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3.amazonaws.com/'
          )
        end

        it 'does not apply to #list_buckets' do
          resp = accelerated_client.list_buckets
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://s3.amazonaws.com/'
          )
        end

        it 'does not apply to #delete_bucket' do
          resp = accelerated_client.delete_bucket(bucket: 'bucket-name')
          expect(resp.context.http_request.endpoint.to_s).to eq(
            'https://bucket-name.s3.amazonaws.com/'
          )
        end

        it 'does not contain `expect` header in request' do
          resp = accelerated_client.put_object(
            bucket: 'bucket-name', key: 'key', body: 'foo'
          )
          expect(resp.context.http_request.headers['expect']).to be_nil
        end

        context ':use_dualstack_endpoint' do
          it 'properly uses the combined endpoint' do
            resp = accel_dualstack_client.put_object(
              bucket: 'bucket-name', key: 'key', use_accelerate_endpoint: true
            )
            expect(resp.context.http_request.endpoint.to_s).to eq(
              'https://bucket-name.s3-accelerate.dualstack.amazonaws.com/key'
            )
          end

          it 'does not apply to #create_bucket' do
            resp = accel_dualstack_client.create_bucket(bucket: 'bucket-name')
            expect(resp.context.http_request.endpoint.to_s).to eq(
              'https://bucket-name.s3.dualstack.us-east-1.amazonaws.com/'
            )
          end

          it 'does not apply to #list_buckets' do
            resp = accel_dualstack_client.list_buckets
            expect(resp.context.http_request.endpoint.to_s).to eq(
              'https://s3.dualstack.us-east-1.amazonaws.com/'
            )
          end

          it 'does not apply to #delete_bucket' do
            resp = accel_dualstack_client.delete_bucket(bucket: 'bucket-name')
            expect(resp.context.http_request.endpoint.to_s).to eq(
              'https://bucket-name.s3.dualstack.us-east-1.amazonaws.com/'
            )
          end

          it 'does not contain `expect` header in request' do
            resp = accel_dualstack_client.put_object(
              bucket: 'bucket-name', key: 'key', body: 'foo'
            )
            expect(resp.context.http_request.headers['expect']).to be_nil
          end
        end
      end
    end
  end
end
