# coding: utf-8
require 'jekyll'
require 'time'
require 'bibsonomy/csl'
require 'digest'

#
# Jekyll Tag to render posts from BibSonomy.
#
# Usage: {% bibsonomy GROUPING NAME TAG1 TAG2 ... TAGN COUNT %}
#   where
#     GROUPING is either "user" or "group" and specifies the type of NAME
#     NAME is the name of the group or user
#     TAG1 ... TAGN are tags
#     COUNT is an integer, the number of posts to return
#
# Changes:
# 2018-10-21
# - add simple cache mechanism
# 2018-10-13
# - added document_link_prefix
# 2018-10-08 (rja)
# - added liquid expansion
# 2017-05-31 (rja)
# - added support for groups and multiple tags
#

module Jekyll

  class BibSonomyPostList < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @input = text
    end

    def render(context)

      # extract config
      site = context.registers[:site]
      bib_config = site.config['bibsonomy']

      # expand liquid variables
      rendered_input = Liquid::Template.parse(@input).render(context)

      # check for cache
      cache_directory = bib_config['cache_directory']
      if not (cache_directory.nil? || cache_directory.empty?)

        # name of cache file with path
        rendered_input_hash = Digest::MD5.hexdigest(rendered_input)
        cache_filepath = bib_config['cache_directory'] + '/' + rendered_input_hash + '.cache'

        # check for cache
        if File.exists? cache_filepath

          # read html from cache file
          File.open(cache_filepath, "r:UTF-8") do |f|
            return f.read
          end
        end
      end

      # parse parameters
      parts = rendered_input.split(/\s+/)
      grouping = parts.shift
      name = parts.shift
      # the last element is the number of posts
      count = Integer(parts.pop)
      # everything else are the tags
      tags = parts

      # user name and API key for BibSonomy
      csl = BibSonomy::CSL.new(bib_config['user'], bib_config['apikey'])

      # target directory for PDF documents
      csl.pdf_dir = bib_config['document_directory']

      # prefix for PDF document links
      csl.pdf_link_prefix = bib_config['document_link_prefix']

      # Altmetric badge type
      csl.altmetric_badge_type = bib_config['altmetric_badge_type']

      # CSL style for rendering
      csl.style = bib_config['style']

      html = csl.render(grouping, name, tags, count)

      # set date to now
      context.registers[:page]["date"] = Time.new

      # cache the resulting html
      if not (cache_directory.nil? || cache_directory.empty?)
        File.open(cache_filepath, "w:UTF-8") do |f| 
          f.write html 
        end 
      end

      return html
    end
  end
end

Liquid::Template.register_tag('bibsonomy', Jekyll::BibSonomyPostList)
