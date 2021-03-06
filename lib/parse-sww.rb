#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true

# Copyright (C) 2019 Jonathan Riddell <jr@jriddell.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'nokogiri'
require 'optparse'
require 'json'

class ParseSww
  attr_accessor :htmlDirectory
  attr_accessor :htmlFiles
  attr_accessor :riverEntries

  def initialize(htmlDirectory)
    @htmlDirectory = htmlDirectory
    @riverEntries = []
  end

  def get_html_files
    Dir.chdir(@htmlDirectory)
    @htmlFiles = Dir.glob('*.html')
    @htmlFiles.sort!
    @htmlFiles.delete("Example pages 1.html")
    puts "#{@htmlFiles}"
  end
  
  def parse_html_files
    @htmlFiles.each do |htmlFile|
      @riverEntries = @riverEntries + parse_html_file(htmlFile)
    end
  end

  def parse_html_file(htmlFile)
    abort "No such file" if not File.exists?(htmlFile)
    puts "PARSING #{htmlFile}"
    swwDoc = SwwDoc.new()
    parser = Nokogiri::HTML::SAX::Parser.new(swwDoc)
    parser.parse(File.read(htmlFile, mode: 'rb'))
    swwDoc.riverEntries
  end

  def json(entries)
    json = []
    @riverEntries.each {|riverEntry| json << riverEntry.to_h}
    JSON.pretty_generate(json[0..entries])
  end

  def save_file
     save_file_name = @filename
     save_file_name = "#{@filename}.testout" if @testing
     f = File.open(save_file_name, "w")
     @doc.write_xml_to(f, {indent: 2})
     f.close
  end
end

class SwwDoc < Nokogiri::XML::SAX::Document
  attr_accessor :riverEntries
  @currentRiverEntry
  @parserState
  # List of sections with no finish location, we set it to be same as start
  @missingFinishLocation
  @missingLength

  def initialize()
    super
    @missingFinishLocation = ['290', '273', '300', '304', '202', '206', '018', '065', '067', '077', '166', '167', '174']
    @missingStartLocation = ['154', '158', '155']
    @missingLength = ['077', '174']
    @riverEntries = []
  end

  def start_element(name, attributes = [])
    puts "found a #{name} atts #{attributes}"
    # end of the book, ignore from now on
    if @parserState == ParserState::Appendix
      puts "start_element ParserState::Appendix returning"
      return
    end
    # Start of a new river
    if name == 'p' and attributes[0].include?('Pesda-Heading-1')
      puts "XXX Pesda-Heading-1"
      @parserState = ParserState::RiverName
    end
    #if name == 'a' and attributes[0].include?('Anchor-7')
    #  puts "Special cast Findhorn header"
    #  @parserState = ParserState::Nothing
    #end
    if name == 'p' and attributes[0].include?('Pesda-Heading-4') and not @currentRiverEntry.nil?
      @parserState = ParserState::RiverSubName
    end
    if name == 'p' and attributes[0].include?('Pesda-Quick-Reference')
      puts "XXX settings to quick ref state\n"
      @parserState = ParserState::PesdaQuickReference
    end
    if name == 'p' and attributes[0].include?('Pesda-Quick-Reference-contributors')
      puts "XXX settings to quick ref contributors\n"
      @parserState = ParserState::PesdaQuickReferenceContributors unless @parserState == ParserState::Contributors
    end
    if name == 'p' and attributes[0].include?('Pesda-Heading-3')
      if not @currentRiverEntry.nil? and not @currentRiverEntry.name.nil?
        @parserState = ParserState::RiverEntryTextHeader
      end
    end
    if name == 'p' and (attributes[0].include?('Pesda-Text-No-Indent') or attributes[0].include?('Pesda-Text-No-Indent para-style-override-5'))
      if not @currentRiverEntry.nil? and not @currentRiverEntry.name.nil?
        @parserState = ParserState::RiverEntryText
      end
    end
    if name == 'p' and attributes[0].include?('Contents-Heading-Section')
      # we found a section listing, ignore
      @parserState = ParserState::Nothing
      @currentRiverEntry = nil
    end
    if name == 'p' and attributes[0].include?('Pesda-Caption')
      # found a photo, ignore
      @parserState = ParserState::Nothing
    end
  end

  def characters(string)
    #puts "#{string}"
    if @parserState == ParserState::Nothing or @parserState == ParserState::Appendix
      return
    end
    # Appendix at the end of the book so ignore the rest
    if string == 'Appendices'
      puts "AAAA Appendices"
      @parserState = ParserState::Appendix
      return
    end
    if @parserState == ParserState::RiverName
      #puts "STRING: " + string + "<<<"
      sectionNumberRegEx = /\d\d\d/
      riverNameRegEx = /\w[-òè’\w ]+/
      if sectionNumberRegEx.match?(string)
        # New section number means new river
        puts "QQQmatched a section number on #{string}"
        @currentRiverEntry = RiverEntry.new
        @riverEntries << @currentRiverEntry
        sectionNumber = sectionNumberRegEx.match(string)
        @currentRiverEntry.sectionNumber = sectionNumber.to_s
        if @missingLength.include?(@currentRiverEntry.sectionNumber)
          @currentRiverEntry.length = '0'
        end
      elsif riverNameRegEx.match?(string)
        riverName = riverNameRegEx.match(string)
        # Special case Findhorn which has a heading before the actual start of the river entry
        puts "YYY ZZZ settings name to #{riverName.to_s}"
        if (riverName.to_s == 'Findhorn') and @currentRiverEntry.nil?
          @parserState = ParserState::Nothing
          return
        end
        # Both North Esks also have a preamble so if we're still on Don or Almond section then skip it
        if (riverName.to_s =~ /North Esk/) and (@currentRiverEntry.sectionNumber == '243' or @currentRiverEntry.sectionNumber == '265')
          @parserState = ParserState::Nothing
          return
        end
        # Spean also has a preamble
        if (riverName.to_s =~ /Spean/) and (@currentRiverEntry.sectionNumber == '143')
          @parserState = ParserState::Nothing
          return
        end
        # Etive also has a preamble
        if (riverName.to_s =~ /Etive/) and (@currentRiverEntry.sectionNumber == '161')
          @parserState = ParserState::Nothing
          return
        end
        # Roy also has a preamble
        if (riverName.to_s =~ /Roy/) and (@currentRiverEntry.sectionNumber == '145')
          @parserState = ParserState::Nothing
          return
        end
        # Tweed is special case cos it has no location
        if (riverName.to_s =~ /Tweed/)
          @currentRiverEntry.startLongitude = '55.5838'
          @currentRiverEntry.startLatitude = '-2.8605'
          @currentRiverEntry.finishLongitude = '55.7226'
          @currentRiverEntry.finishLatitude = '-2.1633'
        end
        if @currentRiverEntry.name.nil?
          @currentRiverEntry.name = ''
        end
        @currentRiverEntry.name += ' ' + riverName.to_s
        @currentRiverEntry.name.strip!
      end
    end
    if @parserState == ParserState::RiverSubName
      @currentRiverEntry.subName = '' if @currentRiverEntry.subName.nil?
      subName = string.strip
      subName.sub!('(', '')
      subName.sub!(')', '')
      @currentRiverEntry.subName += subName
    end
    if @parserState == ParserState::Contributors
      @currentRiverEntry.contributor = '' if @currentRiverEntry.contributor.nil?
      if @currentRiverEntry.contributor.length > 0 and not @currentRiverEntry.contributor.end_with?(' ')
        @currentRiverEntry.contributor += ' '
      end
      @currentRiverEntry.contributor += string.strip
      @currentRiverEntry.contributor.strip!
    end
    if @parserState == ParserState::Grade
      @currentRiverEntry.grade = '' if @currentRiverEntry.grade.nil?
      @currentRiverEntry.grade += string.strip
    end
    if @parserState == ParserState::Length
      @currentRiverEntry.length = '' if @currentRiverEntry.length.nil?
      @currentRiverEntry.length += string.strip
    end
    if @parserState == ParserState::Start
      puts "III start: " + string.strip
      @currentRiverEntry.startGridRef = '' if @currentRiverEntry.startGridRef.nil?
      gridRefRegEx = /\w\w \d\d\d \d\d\d/ # "HU 373 573"
      longLatRegEx = /\d\d\.\d\d\d\d?\d?\d?,? -?\d[\.,]\d\d\d\d?\d?\d?/ # "60.2984, -1.3271"
      @startLocation += string # hopefully something like "HU 373 573 (60.2984, -1.3271)"
      # special case Lugar Water which has missing space
      if @currentRiverEntry.name == 'Lugar Water'
        @startLocation = 'NS 594 214 (55.4661, -4.2255)'
      end
      puts "EEE startLocation: " + @startLocation
      if gridRefRegEx.match?(@startLocation)
        @currentRiverEntry.startGridRef = gridRefRegEx.match(@startLocation).to_s
      end
      if longLatRegEx.match?(@startLocation)
        puts "OOO found a matching startLocation" + @startLocation
        longLat = longLatRegEx.match(@startLocation).to_s
        @currentRiverEntry.startLongitude = longLat.split[0].sub(',','')
        @currentRiverEntry.startLatitude = longLat.split[1].sub(',','.') # entry 249 has a typo and uses a , instead of .
      end
      # These ones have no finish so set to be same as start
      if @missingFinishLocation.include?(@currentRiverEntry.sectionNumber)
        @currentRiverEntry.finishLongitude = @currentRiverEntry.startLongitude
        @currentRiverEntry.finishLatitude = @currentRiverEntry.startLatitude
      end
      # Special case first Keltney Burn which does not parse Finish
      if @currentRiverEntry.startLongitude == '56.6437'
        @currentRiverEntry.finishLongitude = '56.6450'
        @currentRiverEntry.finishLatitude = '-4.0136'
      end
    end
    if @parserState == ParserState::Finish
      @currentRiverEntry.finishGridRef = '' if @currentRiverEntry.finishGridRef.nil?
      gridRefRegEx = /\w\w \d\d\d \d\d\d/ # "HU 373 573"
      longLatRegEx = /\d\d\.\d\d\d\d?\d?\d?,? -?\d[\.,]\d\d\d\d?\d?\d?/ # "60.2984, -1.3271"
      finishLocation = string.strip # hopefully something like "HU 373 573 (60.2984, -1.3271)"
      puts "NNN finish: " + finishLocation
      if gridRefRegEx.match?(finishLocation)
        @currentRiverEntry.finishGridRef = gridRefRegEx.match(finishLocation).to_s
      end
      if longLatRegEx.match?(finishLocation)
        longLat = longLatRegEx.match(finishLocation).to_s
        @currentRiverEntry.finishLongitude = longLat.split[0].sub(',','')
        @currentRiverEntry.finishLatitude = longLat.split[1].sub(',','.') # entry 278 has a typo and uses a , instead of .
      end
      # These ones have no start so set to be same as start
      if @missingStartLocation.include?(@currentRiverEntry.sectionNumber)
        @currentRiverEntry.startLongitude = @currentRiverEntry.finishLongitude
        @currentRiverEntry.startLatitude = @currentRiverEntry.finishLatitude
      end
    end
    if @parserState == ParserState::PesdaQuickReference
      #puts "quick ref:" + string + "<<"
    end
    if @parserState == ParserState::PesdaQuickReferenceContributors and string.include?('Contributor')
       #puts "XXX in contributors state"
      @parserState = ParserState::Contributors
    end
    if @parserState == ParserState::PesdaQuickReference and string.include?('Grade')
      #puts "state now grade"
      @parserState = ParserState::Grade
    end
    if @parserState == ParserState::PesdaQuickReference and string =~ /Length/
      #puts "state now length"
      @parserState = ParserState::Length
    end
    if @parserState == ParserState::PesdaQuickReference and (string =~ /Start/ or string == 'Location')
      puts "state now start"
      @parserState = ParserState::Start
      @startLocation = ''
    end
    if @parserState == ParserState::PesdaQuickReference and (string =~ /Finish/ or string == 'Parking')
      puts "MMM state now finish"
      @parserState = ParserState::Finish
    end
    if @parserState == ParserState::RiverEntryText
      puts "AAAfound text: " + string
      @currentRiverEntry.riverEntryText = '' if @currentRiverEntry.riverEntryText.nil?
      @currentRiverEntry.riverEntryText += string.strip + "\n"
    end
    # Add markdown header markers '##'
    if @parserState == ParserState::RiverEntryTextHeader
      puts "AAAfound header text: " + string
      @currentRiverEntry.riverEntryText = '' if @currentRiverEntry.riverEntryText.nil?
      if /\s+/ =~ string
        @currentRiverEntry.riverEntryText += string.strip + "\n"
      else
        @currentRiverEntry.riverEntryText += '## ' + string.strip + "\n"
      end
    end
  end
end

class RiverEntry
  attr_accessor :sectionNumber
  attr_accessor :name
  attr_accessor :subName
  attr_accessor :contributor
  attr_accessor :grade
  attr_accessor :length
  attr_accessor :startGridRef
  attr_accessor :startLongitude
  attr_accessor :startLatitude
  attr_accessor :finishGridRef
  attr_accessor :finishLongitude
  attr_accessor :finishLatitude
  attr_accessor :riverEntryText
  attr_accessor :sepaGaugeLocationCode
  attr_accessor :gaugeScrapeValue
  attr_accessor :gaugeLowValue
  attr_accessor :gaugeMediumValue
  attr_accessor :gaugeHighValue
  attr_accessor :gaugeVHighValue
  attr_accessor :gaugeHugeValue
  attr_reader   :wtwData

  def wtwData
    return @wtwData if not @wtwData.nil?
    riverSectionsFile = File.read('/home/jr/src/parse-sww/parse-sww/river-sections.json', mode: 'rb')
    @wtwData = JSON.parse(riverSectionsFile)
  end

  # Reads in river-sections.json and adds gauge code and calibrations
  def addWtWData
    @sepaGaugeLocationCode = ''
    @gaugeScrapeValue = ''
    @gaugeLowValue = ''
    @gaugeMediumValue = ''
    @gaugeHighValue = ''
    @gaugeVHighValue = ''
    @gaugeHugeValue = ''
    wtwData.each do |section|
      scaGuidebookNo = section['sca_guidebook_no'].rjust(3, "0") # add leadins 0
      if scaGuidebookNo == sectionNumber
        @sepaGaugeLocationCode = section['gauge_location_code']
        @gaugeScrapeValue = section['scrape_value']
        @gaugeLowValue = section['low_value']
        @gaugeMediumValue = section['medium_value']
        @gaugeHighValue = section['high_value']
        @gaugeVHighValue = section['very_high_value']
        @gaugeHugeValue = section['huge_value']
        break
      end
    end
  end

  def to_str
    string = "RIVER: #{sectionNumber} #{name}\n"
    string += "Subname: #{subName}\n"
    string += "Contributor: #{contributor}\n"
    string += "Grade: #{grade}\n"
    string += "length: #{length}\n"
    string += "start: #{startGridRef} #{startLongitude} #{startLatitude}\n"
    string += "finish: #{finishGridRef} #{finishLongitude} #{finishLatitude}\n"
    string += "riverEntryText: #{riverEntryText[0..30]}…\n\n"
    return string
  end

  def to_h
    addWtWData
    @subName = "Main" if @subName.nil?
    credit = "Section description by " + @contributor + ".\n\n"
    credit += "##Credits\n\nText from SCA Scottish White Water Guidebook, copyright [Scottish Canoe Association](https://www.canoescotland.org/) and [The Andy Jackson Fund for Access](https://www.andyjacksonfund.org.uk/)."
    {sectionNumber: sectionNumber,
     "riverName": name,
     "sectionName": subName,
     grade: grade,
     length: length,
     startLongitude: startLongitude,
     startLatitude: startLatitude,
     finishLongitude: finishLongitude,
     finishLatitude: finishLatitude,
     sepaGaugeLocationCode: sepaGaugeLocationCode,
     gaugeScrapeValue: gaugeScrapeValue,
     gaugeLowValue: gaugeLowValue,
     gaugeMediumValue: gaugeMediumValue,
     gaugeHighValue: gaugeHighValue,
     gaugeVHighValue: gaugeVHighValue,
     gaugeHugeValue: gaugeHugeValue,
     riverEntryText: riverEntryText + "\n\n" + credit
    }
  end
end

module ParserState
  Nothing = 0
  RiverName = 1
  RiverSubName = 2
  Contributors = 3
  Grade = 4
  PesdaQuickReference = 5
  Length = 6
  Start = 7
  Finish = 8
  RiverEntryText = 9
  PesdaQuickReferenceContributors = 10
  RiverEntryTextHeader = 11
  Appendix = 12
end
