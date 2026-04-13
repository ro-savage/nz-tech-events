require 'test_helper'

class HasRegionTest < ActiveSupport::TestCase
  # Test the concern through EventLocation as a concrete model
  # that includes it. All three models (Event, EventLocation,
  # EmailSubscription) share the same concern.

  # -- Enum mappings --

  test 'defines all 18 region values' do
    assert_equal 18, HasRegion::REGIONS.size
  end

  test 'region integer mappings match expected values' do
    expected = {
      northland: 0,
      auckland: 1,
      waikato: 2,
      bay_of_plenty: 3,
      gisborne: 4,
      hawkes_bay: 5,
      taranaki: 6,
      manawatu_whanganui: 7,
      wellington: 8,
      tasman: 9,
      nelson: 10,
      marlborough: 11,
      west_coast: 12,
      canterbury: 13,
      otago: 14,
      southland: 15,
      apac: 16,
      online: 17
    }
    assert_equal expected, HasRegion::REGIONS
  end

  test 'enum is defined with prefix on including models' do
    location = EventLocation.new(region: :auckland)
    assert location.region_auckland?
    assert_not location.region_wellington?
  end

  test 'all three models share the same region mappings' do
    assert_equal Event.regions, EventLocation.regions
    assert_equal Event.regions, EmailSubscription.regions
  end

  # -- region_display --

  test 'region_display returns Asia Pacific for apac' do
    location = EventLocation.new(region: :apac)
    assert_equal 'Asia Pacific', location.region_display
  end

  test 'region_display titleizes single-word regions' do
    location = EventLocation.new(region: :wellington)
    assert_equal 'Wellington', location.region_display
  end

  test 'region_display titleizes multi-word regions with hyphens' do
    location = EventLocation.new(region: :manawatu_whanganui)
    assert_equal 'Manawatu Whanganui', location.region_display
  end

  test 'region_display titleizes bay_of_plenty' do
    location = EventLocation.new(region: :bay_of_plenty)
    assert_equal 'Bay Of Plenty', location.region_display
  end

  test 'region_display returns Online for online' do
    location = EventLocation.new(region: :online)
    assert_equal 'Online', location.region_display
  end

  test 'region_display works on Event model' do
    event = Event.new(region: :apac)
    assert_equal 'Asia Pacific', event.region_display
  end

  test 'region_display works on EmailSubscription model' do
    sub = EmailSubscription.new(region: :apac)
    assert_equal 'Asia Pacific', sub.region_display
  end
end
