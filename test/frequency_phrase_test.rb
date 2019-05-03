require File.expand_path('../helper.rb', __FILE__)

class FrequencyPhraseTest < PapertrailServices::TestCase
  include PapertrailServices::Helpers::LogsHelpers

  def test_1_minute
    assert_equal 'in the past minute', frequency_phrase('1 minute')
  end

  def test_10_minutes
    assert_equal 'in the past 10 minutes', frequency_phrase('10 minutes')
  end

  def test_1_hour
    assert_equal 'in the past hour', frequency_phrase('1 hour')
  end

  def test_1_day
    assert_equal 'in the past day', frequency_phrase('1 day')
  end
end
