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

class ParseSww
  attr_accessor :htmlDirectory
  attr_accessor :htmlFiles
  attr_accessor :riverEntires

  def initialize(htmlDirectory)
    @htmlDirectory = htmlDirectory
  end

  def get_html_files
    Dir.chdir(@htmlDirectory)
    @htmlFiles = Dir.glob('*.html')
    puts "#{@htmlFiles}"
  end
  
  def parse_html_files
    @htmlFiles.each do |htmlFile|
      parse_html_file(htmlFile)
    end
  end

  def parse_html_file(htmlFile)
    abort "No such file" if not File.exists?(htmlFile)
    puts "PARSING #{htmlFile}"
    swwDoc = SwwDoc.new()
    parser = Nokogiri::HTML::SAX::Parser.new(swwDoc)
    parser.parse(File.read(htmlFile, mode: 'rb'))
    @riverEntries = swwDoc.riverEntries
    puts "RESULT: #{@riverEntries}"
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
      @riverEntries << @currentRiverEntry if not @currentRiverEntry.nil?
      @currentRiverEntry = RiverEntry.new
      @parserState = ParserState::FoundRiverName
      @currentRiverEntry.name = ''
    end
  end

  def characters(string)
    puts "#{string}"
    if @parserState == ParserState::FoundRiverName
      puts "XXX string!"
      @currentRiverEntry.name += string
    end
  end
end

class RiverEntry
  attr_accessor :name
  #@name
  @subName
  @contributor
  @grade
  @length
end

module ParserState
  FoundRiverName = 1
end
