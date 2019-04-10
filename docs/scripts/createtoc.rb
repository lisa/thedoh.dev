#!/usr/bin/env ruby

require 'yaml'

TOCFILE = "_data/toc.yaml".freeze

DEST = ARGV[1]
class Page
  attr :category, :parentcategory, :title, :filepath, :children
  def initialize(title,parentcategory,category,filepath)
    @title = title
    @parentcategory = parentcategory
    @category = category
    @filepath = filepath
    @children = []
  end

  def render
    ret = {}
    ret["title"] = @title
    ret["subtoc"] = @children.map { |m| m.render } if @children.size > 0
    ret["url"] = @filepath
    ret
  end

  def has_parent?
    @parentcategory != ""
  end
end

def find_parent(pages, page)
  pages.each do |pag|
    if pag.category == page.parentcategory
      return pag
    end
  end
  return nil
end


pages = []

ARGV[1..ARGV.size].each do |tocfile|
  puts "* Parsing #{tocfile}"
  y = YAML::load(File.read(tocfile))
  puts "  * yaml = #{y.to_s}"
  pages <<Page.new(y['title'],y['parentcategory'],y['category'],tocfile.gsub(/^\./,"").gsub(/\.md/,".html"))
end
todelete = []
pages.each do |page|
  parent = find_parent(pages, page)
  if ! parent.nil?
    # i have a parent
    parent.children << page
    todelete << page
  end
end
pages -= todelete

list = pages.map{|g| g.render}

File.open(TOCFILE,"w") do |f|
  f.print({"toc" => list}.to_yaml)
end