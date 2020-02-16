#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/parse-sww'

class ParseSwwTest < MiniTest::Test
  def test_get_html_files
    parseSww = ParseSww.new('/home/jr/src/parse-sww/SWW - web resources/')
    parseSww.get_html_files()
    assert_equal(["2 The West.html", "4 The South.html", "3 The East.html", "Example pages 1.html", "1 The North.html"], parseSww.htmlFiles)
  end
    
  def test_parse_html_file_burn1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/burn1/')
    parseSww.get_html_files()
    assert_equal(["burn1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(1, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Burn of Lunklet', riverEntry.name)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3(4-)', riverEntry.grade)
    assert_equal('1km', riverEntry.length)
    assert_equal('HU 373 573', riverEntry.startGridRef)
    assert_equal('60.2984', riverEntry.startLongitude)
    assert_equal('-1.3271', riverEntry.startLatitude)
    assert_equal('HU 367 576', riverEntry.finishGridRef)
    assert_equal('60.3005', riverEntry.finishLongitude)
    assert_equal('-1.3385', riverEntry.finishLatitude)
    puts "Testing for text: " + riverEntry.riverEntryText
    assert_equal("Access\n\nDrive north from Lerwic", riverEntry.riverEntryText[0..30])
  end

  def test_parse_html_file_burn2
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/burn2/')
    parseSww.get_html_files()
    assert_equal(["burn2.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(1, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Burn of Crookadale', riverEntry.name)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3/4', riverEntry.grade)
    assert_equal('200m', riverEntry.length)
    assert_equal('HU 437 538', riverEntry.startGridRef)
    assert_equal('60.2664', riverEntry.startLongitude)
    assert_equal('-1.2119', riverEntry.startLatitude)
    assert_equal('HU 437 538', riverEntry.finishGridRef)
    assert_equal('60.2664', riverEntry.finishLongitude)
    assert_equal('-1.2119', riverEntry.finishLatitude)
    puts "Testing for text: " + riverEntry.riverEntryText
    assert_equal("Access\n\nFrom the A970 driving n", riverEntry.riverEntryText[0..30])
  end

  def test_parse_html_file_multirivers1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/multirivers1/')
    parseSww.get_html_files()
    assert_equal(["multirivers1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(3, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Helmsdale', riverEntry.name)
    assert_equal('John Ross, Gary Smith, Colin Matheson and Ron Cameron', riverEntry.contributor)
    assert_equal('3/4(4+)', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Kilphedir Burn', riverEntry.name)
    assert_equal('Colin Matheson', riverEntry.contributor)
    assert_equal('4(5)', riverEntry.grade)
    riverEntry = parseSww.riverEntries[2]
    assert_equal('Berriedale Water', riverEntry.name)
    assert_equal('John Ross, Gary Smith and Colin Matheson', riverEntry.contributor)
    assert_equal('2/3(5)', riverEntry.grade)
  end

=begin
  def test_parse_html_file_section1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/section1/')
    parseSww.get_html_files()
    assert_equal(["section1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(3, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    puts "UUU grade #{riverEntry.grade}"
    puts "UUU contributors #{riverEntry.contributor}"
    assert_equal('Burn of Crookadale', riverEntry.name)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3/4', riverEntry.grade)
  end
=end
end
