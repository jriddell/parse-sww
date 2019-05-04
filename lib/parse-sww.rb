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

  def initialize(htmlDirectory)
    @htmlDirectory = htmlDirectory
  end

  def get_html_files()
    puts "get_html_files"
    Dir.chdir(@htmlDirectory)
    @htmlFiles = Dir.glob('*.html')
    puts "#{@htmlFiles}"
  end
  
  
  
  def open_file
    abort "No such file" if not File.exists?(@filename)
    @doc = File.open(@filename) { |f| Nokogiri::XML(f, &:noblanks) }
    component = @doc.at_css("component")
    releases = @doc.at_css("releases")
    if releases and @date_off
      releases.add_child("<release version='#{@version}'/>")
    elsif not releases and @date_off
      component.add_child("<releases><release version='#{@version}'/></releases>")
    elsif releases and not @date_off
      releases.add_child("<release version='#{@version}' date='#{date}'/>")
    else
      component.add_child("<releases><release version='#{@version}' date='#{date}'/></releases>")
    end
    if releases and @releases_to_show > 0
      if releases.children.length > @releases_to_show
        releases.children = releases.children[-@releases_to_show,@releases_to_show]
      end
    end
  end

  def save_file
     save_file_name = @filename
     save_file_name = "#{@filename}.testout" if @testing
     f = File.open(save_file_name, "w")
     @doc.write_xml_to(f, {indent: 2})
     f.close
  end
end
