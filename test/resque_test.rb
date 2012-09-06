require_relative 'test_helper'

# make sure the worlds not fallen from beneith us.
class ResqueTest < Test::Unit::TestCase
  def test_resque_version
    major, minor, patch = Resque::Version.split('.')
    assert_equal 1, major.to_i, 'major version does not match'
    assert_operator minor.to_i, :>=, 8, 'minor version is too low'
  end
end
