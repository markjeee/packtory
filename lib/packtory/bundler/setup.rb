# Adding require paths to load path (empty if no gems is needed)

require 'rubygems'

ENV['GEM_HOME'] = ''
ENV['GEM_PATH'] = ''
Gem.clear_paths

<%
packer.for_each_bundle_gems do |gem_name, bhash, rpaths|
  concat("# == Gem: %s, version: %s\n" % [ bhash[:spec].name, bhash[:spec].version ])

  rpaths.each do |rpath|
    concat("$:.unshift File.expand_path('../../%s%s', __FILE__)\n" % [ gem_name, rpath ])
  end

  concat("\n")
end
%>
