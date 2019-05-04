require 'minitest/autorun'
require_relative '../lib/parse-sww'

class ParseSwwTest < MiniTest::Test
  def test_get_html_files
    parseSww = ParseSww.new('/home/jr/Documents/white-water-guidebook/SWW - web resources/')
    parseSww.get_html_files()
    assert_equal(["3 The East.html", "Example pages 1.html", "2 The West.html", "4 The South.html", "1 The North.html"], parseSww.htmlFiles)
  end
    
=begin    
  # adding a release to a file with no releases
  def test_no_releases
    file = "no-releases"
    updater = MetaInfoUpdater.new("data/#{file}.appdata.xml", "1.0", "2018-01-01", false)
    updater.testing = true
    updater.open_file
    updater.save_file
    assert_equal(File.read("data/#{file}.appdata.xml.expected"), File.read("data/#{file}.appdata.xml.testout"))
  end

  # date off
  def test_no_releases_date_off
    file = "no-releases-date-off"
    updater = MetaInfoUpdater.new("data/#{file}.appdata.xml", "1.0", "today", true)
    updater.testing = true
    updater.open_file
    updater.save_file
    assert_equal(File.read("data/#{file}.appdata.xml.expected"), File.read("data/#{file}.appdata.xml.testout"))
  end

  # adding a release to a file with 1 release
  def test_one_release
    file = "one-release"
    updater = MetaInfoUpdater.new("data/#{file}.appdata.xml", "2.0", "2018-01-01", false)
    updater.testing = true
    updater.open_file
    updater.save_file
    assert_equal(File.read("data/#{file}.appdata.xml.expected"), File.read("data/#{file}.appdata.xml.testout"))
  end

  # adding a release to a file with 5 releases and limit set to 4
  def test_five_releases
    file = "five-releases"
    updater = MetaInfoUpdater.new("data/#{file}.appdata.xml", "6.0", "2018-01-01", false, 4)
    updater.testing = true
    updater.open_file
    updater.save_file
    assert_equal(File.read("data/#{file}.appdata.xml.expected"), File.read("data/#{file}.appdata.xml.testout"))
  end
=end
end
