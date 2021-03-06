# frozen_string_literal: true
require 'spec_helper'
require 'zendesk_apps_tools/cache'
require 'tmpdir'
require 'fileutils'

describe ZendeskAppsTools::Cache do
  context 'with a local cache file' do
    let(:cache) { ZendeskAppsTools::Cache.new(path: tmpdir) }
    let(:tmpdir) { Dir.mktmpdir }

    before do
      content = JSON.dump(subdomain: 'under-the-domain', username: 'Roger', app_id: 12)
      File.write(File.join(tmpdir, '.zat'), content, mode: 'w')
    end

    after do
      FileUtils.rm_r tmpdir
    end

    describe '#fetch' do
      it 'reads data from the cache' do
        expect(cache.fetch('username')).to eq 'Roger'
      end

      context 'with a global cache' do
        before do
          fake_home = File.join(tmpdir, 'fake_home')
          FileUtils.mkdir_p(fake_home)
          allow(Dir).to receive(:home).and_return(fake_home)
          global_content = JSON.dump(global_subdomain: { password: 'hunter2' }, default: { subdomain: 'default-domain', password: 'hunter3' })
          File.write(File.join(fake_home, '.zat'), global_content, mode: 'w')
        end

        it 'falls back to global cache' do
          expect(cache.fetch('password', 'global_subdomain')).to eq 'hunter2'
        end

        it 'falls back to global cache default' do
          expect(cache.fetch('password')).to eq 'hunter3'
        end
      end
    end

    describe '#save' do
      it 'works' do
        cache.save(other_key: 'value')
        expect(JSON.parse(File.read(File.join(tmpdir, '.zat')))['other_key']).to eq 'value'
      end
    end

    describe '#clear' do
      it 'does nothing by default' do
        cache.clear
        expect(File.exist?(File.join(tmpdir, '.zat'))).to be_truthy
      end

      it 'works' do
        cache = ZendeskAppsTools::Cache.new(path: tmpdir, clean: true)
        cache.clear
        expect(File.exist?(File.join(tmpdir, '.zat'))).to be_falsey
      end
    end
  end
end
