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

  def initialize()
    super
    @riverEntries = []
  end

  def start_element(name, attributes = [])
    puts "found a #{name} atts #{attributes}"
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
    if @parserState == ParserState::Nothing
      return
    end
    if @parserState == ParserState::RiverName
      puts "STRING: " + string + "<<<"
      sectionNumberRegEx = /\d\d\d/
      riverNameRegEx = /\w[-ò’\w ]+/
      if sectionNumberRegEx.match?(string)
        # New section number means new river
        puts "QQQmatched a section number on #{string}"
        @currentRiverEntry = RiverEntry.new
        @riverEntries << @currentRiverEntry
        sectionNumber = sectionNumberRegEx.match(string)
        @currentRiverEntry.sectionNumber = sectionNumber.to_s
      elsif riverNameRegEx.match?(string)
        riverName = riverNameRegEx.match(string)
        # Special case Findhorn which has a heading before the actual start of the river entry
        puts "YYY ZZZ settings name to #{riverName.to_s}"
        if (riverName.to_s == 'Findhorn') and @currentRiverEntry.nil?
          @parserState = ParserState::Nothing
          return
        end
        # North esk also has a preamble so if we're still on Don section then skip it
        if (riverName.to_s == 'North Esk') and @currentRiverEntry.sectionNumber == '243'
          @parserState = ParserState::Nothing
          return
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
      @currentRiverEntry.startGridRef = '' if @currentRiverEntry.startGridRef.nil?
      gridRefRegEx = /\w\w \d\d\d \d\d\d/ # "HU 373 573"
      longLatRegEx = /\d\d\.\d\d\d\d, -?\d\.\d\d\d\d/ # "60.2984, -1.3271"
      startLocation = string.strip # hopefully something like "HU 373 573 (60.2984, -1.3271)"
      if gridRefRegEx.match?(startLocation)
        @currentRiverEntry.startGridRef = gridRefRegEx.match(startLocation).to_s
      end
      if longLatRegEx.match?(startLocation)
        longLat = longLatRegEx.match(startLocation).to_s
        @currentRiverEntry.startLongitude = longLat.split[0].sub(',','')
        @currentRiverEntry.startLatitude = longLat.split[1]
      end
    end
    if @parserState == ParserState::Finish
      @currentRiverEntry.finishGridRef = '' if @currentRiverEntry.finishGridRef.nil?
      gridRefRegEx = /\w\w \d\d\d \d\d\d/ # "HU 373 573"
      longLatRegEx = /\d\d\.\d\d\d\d, -?\d\.\d\d\d\d/ # "60.2984, -1.3271"
      finishLocation = string.strip # hopefully something like "HU 373 573 (60.2984, -1.3271)"
      if gridRefRegEx.match?(finishLocation)
        @currentRiverEntry.finishGridRef = gridRefRegEx.match(finishLocation).to_s
      end
      if longLatRegEx.match?(finishLocation)
        longLat = longLatRegEx.match(finishLocation).to_s
        @currentRiverEntry.finishLongitude = longLat.split[0].sub(',','')
        @currentRiverEntry.finishLatitude = longLat.split[1]
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
    if @parserState == ParserState::PesdaQuickReference and string == 'Length'
      #puts "state now length"
      @parserState = ParserState::Length
    end
    if @parserState == ParserState::PesdaQuickReference and string == 'Start'
      #puts "state now start"
      @parserState = ParserState::Start
    end
    if @parserState == ParserState::PesdaQuickReference and string == 'Finish'
      #puts "state now finish"
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
        @currentRiverEntry.riverEntryText += '##' + string.strip + "\n"
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
    @subName = "Main" if @subName.nil?
    credit = "Section description by " + @contributor + ".\n\n"
    credit += "##Credits\n\nText from SCA Scottish White Water Guidebook, copyright [Scottish Canoe Association](https://www.canoescotland.org/) and [The Andy Jackson Fund for Access](https://www.andyjacksonfund.org.uk/)."
    {sectionNumber: sectionNumber,
     "river name": name,
     "section name": subName,
     grade: grade,
     length: length,
     startLongitude: startLongitude,
     startLatitude: startLatitude,
     finishLongitude: finishLongitude,
     finishLatitude: finishLatitude,
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
end
