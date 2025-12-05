require 'rails_helper'

RSpec.describe Authentication::BearerTokenExtractor do
  describe '#extract' do
    context 'on success' do
      let(:valid_header) { 'Bearer token'}
      it 'returns the token' do
        extractor = Authentication::BearerTokenExtractor.new(valid_header)
        expect(extractor.extract).to eq('token')
      end
    end

    context 'on failure' do

      let(:invalid_header) { 'Invalid Token'}
      let(:missing_token_header) { 'Bearer'}
 
      it 'raises error when header does not start with "Bearer"' do
        extractor = Authentication::BearerTokenExtractor.new(invalid_header)
        expect { extractor.extract }.to raise_error(Authentication::BearerTokenExtractor::InvalidFormatError)
      end

      it 'raises error when header does not have exactly 2 parts' do
        extractor = Authentication::BearerTokenExtractor.new(missing_token_header)
        expect { extractor.extract }.to raise_error(Authentication::BearerTokenExtractor::InvalidFormatError)
      end
    end
  end
end