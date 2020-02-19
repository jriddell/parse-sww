#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/parse-sww'

class ParseSwwTest < MiniTest::Test
  def test_get_html_files
    parseSww = ParseSww.new('/home/jr/src/parse-sww/SWW - web resources/')
    parseSww.get_html_files()
    assert(parseSww.htmlFiles.include?("1 The North.html"))
  end

  # a river section
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
    assert_equal("##Access\n\nDrive north from Lerw", riverEntry.riverEntryText[0..30])
    # check the credit for the author and funds is added
    riverEntryJson = parseSww.json(1)
    assert_equal("s://www.andyjacksonfund.org.uk/", riverEntryJson[-40..-10])
  end

  # another river section
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
    assert_equal("##Access\n\nFrom the A970 driving", riverEntry.riverEntryText[0..30])
  end

  # north esk also has a river preamble which we need to special case to ignore
  def test_parse_html_file_northesk1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/northesk1/')
    parseSww.get_html_files()
    assert_equal(["northesk1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(6, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Don', riverEntry.name)
    assert_equal('Calum Peden', riverEntry.contributor)
    assert_equal('2/3+', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('North Esk', riverEntry.name)
    assert_equal('Mark Sherriff', riverEntry.contributor)
    assert_equal('4/4+', riverEntry.grade)
    riverEntry = parseSww.riverEntries[2]
    assert_equal('North Esk', riverEntry.name)
    assert_equal('Mark Sherriff', riverEntry.contributor)
    assert_equal('2(3+)', riverEntry.grade)
  end

  # spean has a river preamble too
  def test_parse_html_file_riverpreamble1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/riverpreamble1/')
    parseSww.get_html_files()
    assert_equal(["riverpreamble1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(5, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Allt Coire Laire', riverEntry.name)
    assert_equal('Kenny Biggin', riverEntry.contributor)
    assert_equal('4/5', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Spean', riverEntry.name)
    assert_equal('Alastair Collis', riverEntry.contributor)
    assert_equal('3+/4', riverEntry.grade)
    riverEntry = parseSww.riverEntries[2]
    assert_equal('Spean', riverEntry.name)
    assert_equal('Alastair Collis', riverEntry.contributor)
    assert_equal('3+(5)', riverEntry.grade)
  end

  # north sannox is followed by the next section, we need to tell is when to stop
  def test_parse_html_file_northsannox
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/northsannox/')
    parseSww.get_html_files()
    assert_equal(["northsannox.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(2, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('North Sannox Burn', riverEntry.name)
    assert_equal('Brendan Emery', riverEntry.contributor)
    assert_equal('4/5', riverEntry.grade)
    puts riverEntry.riverEntryText
    included = riverEntry.riverEntryText.include?('Burns Country')
    assert(!included)
    #assert(riverEntry.text.contains?
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Doon', riverEntry.name)
    assert_equal('Neil Farmer and Alex Lumsden', riverEntry.contributor)
    assert_equal('3', riverEntry.grade)
  end

  # test what happens at the end of the book where we get appendixes
  def test_parse_html_file_appendix
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/appendix/')
    parseSww.get_html_files()
    assert_equal(["appendix.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(1, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Hermitage Water', riverEntry.name)
    assert_equal('Mark Watson and Corey Watson', riverEntry.contributor)
    assert_equal('3/3+', riverEntry.grade)
    puts riverEntry.riverEntryText
    included = riverEntry.riverEntryText.include?('River and place names in Scotland')
    assert(!included)
  end

  # not parsing locations
  def test_parse_html_file_location1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/location1/')
    parseSww.get_html_files()
    assert_equal(["location1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(1, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Pinkston Watersports', riverEntry.name)
    assert_equal('Jonathan Riddell', riverEntry.contributor)
    assert_equal('2(3)', riverEntry.grade)
    assert_equal('55.8727', riverEntry.startLongitude)
    assert_equal('-4.2493', riverEntry.startLatitude)
    puts riverEntry.riverEntryText
    included = riverEntry.riverEntryText.include?('River and place names in Scotland')
    assert(!included)
  end

  # multiple sections in 1 document
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

  # This has multiple sections including a river with two entries
  def test_parse_html_file_section1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/section1/')
    parseSww.get_html_files()
    assert_equal(["section1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(4, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Brora', riverEntry.name)
    assert_equal('Upper', riverEntry.subName)
    assert_equal('John Ross and Gary Smith', riverEntry.contributor)
    assert_equal('2', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Brora', riverEntry.name)
    assert_equal('Lower', riverEntry.subName)
    assert_equal('John Ross and Gary Smith', riverEntry.contributor)
    assert_equal('2', riverEntry.grade)
    riverEntry = parseSww.riverEntries[2]
    assert_equal('Allt a’ Mhuilin', riverEntry.name)
    assert_equal('Glen Brora', riverEntry.subName)
    assert_equal('Richard Bannister, Dave Russell and Vincent Baker', riverEntry.contributor)
    assert_equal('4+', riverEntry.grade)
  end

  # Testing the document from the opening <html> and stuff
  def test_parse_html_file_docstart1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/docstart1/')
    parseSww.get_html_files()
    assert_equal(["docstart1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(2, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Burn of Lunklet', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3(4-)', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Burn of Crookadale', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3/4', riverEntry.grade)
  end

  # East 3 top doc Findhorn
  def test_parse_html_file_docstart2
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/docstart2/')
    parseSww.get_html_files()
    assert_equal(["docstart2.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(4, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Findhorn', riverEntry.name)
    assert_equal('Top', riverEntry.subName)
    assert_equal('Jim Gibson', riverEntry.contributor)
    assert_equal('3(4)', riverEntry.grade)
  end

  # Broke it cos no header 3 and name had a dash in it
  def test_parse_html_file_break1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/break1/')
    parseSww.get_html_files()
    assert_equal(["break1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(2, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Elchaig', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Richard Bannister', riverEntry.contributor)
    assert_equal('2/3 (4+)', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('An Leth-allt', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Richard Bannister', riverEntry.contributor)
    assert_equal('5?', riverEntry.grade)
  end

  # Some part of Muick breaks this
  def test_parse_html_file_break2
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/break2/')
    parseSww.get_html_files()
    assert_equal(["break2.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(2, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Muick', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Bridget Thomas, Andy Jackson and Calum Peden', riverEntry.contributor)
    assert_equal('3+(5)', riverEntry.grade)
    riverEntry = parseSww.riverEntries[1]
    assert_equal('Gairn', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Andy Jackson', riverEntry.contributor)
    assert_equal('3/4', riverEntry.grade)
  end

  # title in style <span xml:lang="en-US">Allt </span>a’<span xml:lang="en-US"> Chaorainn</span>
  def test_parse_html_file_title1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/title1/')
    parseSww.get_html_files()
    assert_equal(["title1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(1, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Allt a’ Chaorainn Mhòir', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Andy Jackson and Richard Bannister', riverEntry.contributor)
    assert_equal('4(5)', riverEntry.grade)
  end

  # all of the north.html
  def test_parse_html_file_full1
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/full1/')
    parseSww.get_html_files()
    assert_equal(["full1.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(112, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Burn of Lunklet', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Chris Curry', riverEntry.contributor)
    assert_equal('3(4-)', riverEntry.grade)
  end

  # all of the west.html
  def test_parse_html_file_full2
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/full2/')
    parseSww.get_html_files()
    assert_equal(["full2.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(109, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Allt Camgharaidh', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Andy Jackson and Kirsten Rendle', riverEntry.contributor)
    assert_equal('4(5)', riverEntry.grade)
  end

  # all of the east.html
  def test_parse_html_file_full3
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/full3/')
    parseSww.get_html_files()
    assert_equal(["full3.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(86, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Findhorn', riverEntry.name)
    assert_equal('Top', riverEntry.subName)
    assert_equal('Jim Gibson', riverEntry.contributor)
    assert_equal('3(4)', riverEntry.grade)
  end

  # all of the south.html
  def test_parse_html_file_full4
    parseSww = ParseSww.new('/home/jr/src/parse-sww/parse-sww/test/data/full4/')
    parseSww.get_html_files()
    assert_equal(["full4.html"], parseSww.htmlFiles)
    parseSww.parse_html_files()
    assert_equal(62, parseSww.riverEntries.length)
    riverEntry = parseSww.riverEntries[0]
    assert_equal('Avon', riverEntry.name)
    assert_nil(riverEntry.subName)
    assert_equal('Douglas Rae', riverEntry.contributor)
    assert_equal('2/3', riverEntry.grade)
  end
end
