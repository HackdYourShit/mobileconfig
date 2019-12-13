# frozen_string_literal: true

require "parallel"
require "uri"

require_relative "./collector"

class Crawler
  attr_reader :path_to_list

  SKIP_DOWNLOADED = true

  def initialize(path_to_list)
    @path_to_list = path_to_list
  end

  def crawl
    raise ArgumentError, "Please input a valid file path" unless valid_input?

    Parallel.each(urls) do |url|
      collector = Collector.new(url)
      next if SKIP_DOWNLOADED && collector.downloaded?
      next unless collector.mobileconfig?

      puts "Found .mobileconfig on #{url}"
      collector.download
    end
  end

  def urls
    hosts.map do |ipv4|
      ["http://#{ipv4}", "https://#{ipv4}"]
    end.flatten
  end

  def hosts
    File.readlines(path_to_list).map(&:chomp).map do |line|
      URI(line).host
    end
  end

  def valid_input?
    return false unless path_to_list

    File.exist?(path_to_list)
  end
end

path = ARGV[0]

crawler = Crawler.new(path)
crawler.crawl
