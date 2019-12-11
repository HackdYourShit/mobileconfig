# frozen_string_literal: true

require "parallel"

require_relative "./collector"

class Crawler
  attr_reader :path_to_list

  def initialize(path_to_list)
    @path_to_list = path_to_list
  end

  def crawl
    raise ArgumentError, "Please input a valid file path" unless valid_input?

    Parallel.each(urls) do |url|
      collector = Collector.new(url)
      next unless collector.mobileconfig?

      puts "Found .mobileconfig on #{url}"
      collector.download
    end
  end

  def urls
    ipv4s.map do |ipv4|
      ["http://#{ipv4}", "https://#{ipv4}"]
    end.flatten
  end

  def ipv4s
    File.readlines(path_to_list).map(&:chomp)
  end

  def valid_input?
    return false unless path_to_list

    File.exist?(path_to_list)
  end
end

path = ARGV[0]

crawler = Crawler.new(path)
crawler.crawl
