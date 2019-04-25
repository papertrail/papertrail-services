require File.expand_path('../helper.rb', __FILE__)

class PluralizeTest < PapertrailServices::TestCase
  def test_pluralize_multiple_items
    assert_equal '42 towels', Pluralize.new('towel', :count => 42).to_s
  end

  def test_pluralize_single_item
    assert_equal '1 towel', Pluralize.new('towel', :count => 1).to_s
  end

  def test_plurlaize_without_count
    assert_equal 'towels',
      Pluralize.new('towel', :omit_count => true, :count => 42).to_s
  end

  def test_pluralize_with_specific_plural
    assert_equal '42 stuffs',
      Pluralize.new('towel', :plural => 'stuffs', :count => 42).to_s
  end
end
