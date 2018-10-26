# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gemfile' do
  context 'Domain Gemfile' do
    it 'have gems locked at the same version as a global Gemfile' do
      global_environment = Bundler::Dsl.evaluate( 'Gemfile', 'Gemfile.lock', {} )
                                       .resolve
                                       .to_hash
      local_environment = Bundler::Dsl.evaluate( 'domain/Gemfile', 'domain/Gemfile.lock', {} )
                                      .resolve
                                      .to_hash

      diff = local_environment.reject do |gem, specifications|
        global_environment[ gem ].map( &:version ).uniq == specifications.map( &:version ).uniq
      end

      expect( diff.keys ).to eq( [] )
    end
  end

  context 'Repreentations Gemfile' do
    it 'have gems locked at the same version as a global Gemfile' do
      global_environment = Bundler::Dsl.evaluate( 'Gemfile', 'Gemfile.lock', {} )
                                       .resolve
                                       .to_hash
      local_environment = Bundler::Dsl.evaluate( 'representations/Gemfile', 'representations/Gemfile.lock', {} )
                                      .resolve
                                      .to_hash

      diff = local_environment.reject do |gem, specifications|
        global_environment[ gem ].map( &:version ).uniq == specifications.map( &:version ).uniq
      end

      expect( diff.keys ).to eq( [] )
    end
  end
end
