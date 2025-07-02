require 'rails_helper'

RSpec.describe 'Routing', type: :routing do
  it 'routes /up to rails/health#show' do
    expect(get: '/up').to route_to('rails/health#show')
  end

  it 'routes POST /v1/user/check_status to v1/users#check_status' do
    expect(post: '/v1/user/check_status').to route_to('v1/users#check_status')
  end

  it 'routes unmatched paths to application#route_not_found' do
    expect(get: '/some/random/path').to route_to(controller: 'application', action: 'route_not_found',
                                                 unmatched: 'some/random/path')
    expect(post: '/another/path').to route_to(controller: 'application', action: 'route_not_found',
                                              unmatched: 'another/path')
  end
end
