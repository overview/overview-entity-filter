#!/usr/bin/env ruby

require './spec/spec_helper'

describe 'My Feature' do
  before do
    @user = admin_session.create_test_user
    page.log_in_as(@user)
    page.create_document_set_from_csv('files/entity-filter-spec.csv')
    page.create_custom_view(name: 'Entity Filter', url: 'http://plugin-entity-filter')
  end

  after do
    admin_session.destroy_test_user(@user)
  end

  it 'should find an entity' do
    page.within_frame('view-app-iframe', wait: WAIT_LOAD) do # wait for plugin to begin loading
      # By default, "English: Google Books words" are removed.
      page.assert_selector('li.filter.selected', wait: WAIT_LOAD) # wait for page to load
      page.assert_selector('td.token', text: 'flizzle', wait: WAIT_LOAD) # wait for filter to run
    end
  end

  it 'should search by country' do
    # Wait for document list to load, so we can wait for it to _change_ later
    page.assert_selector('h3', text: 'Third', wait: WAIT_LOAD)

    page.within_frame('view-app-iframe', wait: WAIT_LOAD) do # wait for plugin to begin loading
      page.assert_selector('li.filter.selected', wait: WAIT_LOAD) # wait for page to load
      page.check('Geonames: Countries')
      page.find('td.token span.name', text: 'canada', wait: WAIT_LOAD).click # wait for geo-finding
    end

    page.assert_no_selector('h3', text: 'Third', wait: WAIT_LOAD) # wait for old list -> loading...
    page.assert_no_selector('h3', text: 'Finding Documents', wait: WAIT_LOAD) # wait for loading... -> new list
    page.assert_selector('h3', text: 'First', wait: WAIT_FAST) # wait for doclist to render
    page.assert_no_selector('h3', text: 'Fourth')
  end

  it 'should remember a search across browser refresh' do
    page.within_frame('view-app-iframe', wait: WAIT_LOAD) do # wait for plugin to begin loading
      page.assert_selector('li.filter.selected', wait: WAIT_LOAD) # wait for page to load
      page.uncheck('English: Google Books words')
      page.check('Geonames: Countries')
      page
        .find('tr[data-token-name=canada]', wait: WAIT_LOAD) # wait for geo-finding
        .find('button[title="Hide this entity"]').click
      sleep(1) # wait for AJAX request to go through
    end

    page.refresh

    page.within_frame('view-app-iframe', wait: WAIT_LOAD) do # wait for plugin to begin loading
      page.assert_selector('li.filter.selected', text: 'Geonames: Countries', wait: WAIT_LOAD) # wait for page load
      page.assert_selector('li.filter:not(.selected)', text: 'English: Google Books words')
      page.assert_selector('.blacklist li.token', text: 'canada')
    end
  end
end
