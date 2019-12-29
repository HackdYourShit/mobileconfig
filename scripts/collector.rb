# frozen_string_literal: true

require "down/http"
require "fileutils"
require "http"
require "oga"
require "openssl"

class Collector
  attr_reader :url

  def initialize(url)
    @url = normalize_url(url)
  end

  def mobileconfig?
    mobileconfig_links.any?
  end

  def mobileconfig_links
    links.select do |link|
      link.end_with? ".mobileconfig"
    end.map do |link|
      to_url link
    end
  end

  def downloaded?
    Dir.exist? base_dir
  end

  def download
    FileUtils.mkdir_p base_dir
    down = Down::Http.new(default_options)

    mobileconfig_links.each do |link|
      basename = File.basename(link)
      begin
        dest = download_to(basename)
        down.download(link, destination: dest) unless File.exist?(dest)
      rescue Down::Error => e
        puts "Failed to download #{link} (#{e})"
      end
    end
  end

  private

  def body
    res = HTTP.timeout(3).get(url, default_options)
    res.body.to_s
  rescue HTTP::Error, OpenSSL::SSL::SSLError => _e
    nil
  end

  def doc
    return nil unless body

    begin
      @doc ||= Oga.parse_html(body)
    rescue ArgumentError, LL::ParserError => _e
      nil
    end
  end

  def links
    (a_links + js_links).compact.uniq
  end

  def a_links
    return [] unless doc

    begin
      doc.css("a").map do |a|
        a.get("href")
      end.compact
    rescue NoMethodError => _e
      []
    end
  end

  def js_links
    return [] unless body

    begin
      body.lines.map(&:strip).select do |line|
        line.include? "location.href"
      end.map do |line|
        line.split.last.gsub(/"|'|;/, "")
      end
    rescue NoMethodError => _e
      []
    end
  end

  def to_url(href)
    return href if href.start_with?("http://", "https://")

    if href.start_with?("/")
      url + href
    else
      "#{url}/#{href}"
    end
  end

  def normalize_url(url)
    url.end_with?("/") ? url[0..-2] : url
  end

  def host
    URI(url).host
  end

  def base_dir
    @base_dir ||= File.expand_path("../samples/#{host}/", __dir__)
  end

  def download_to(basename)
    "#{base_dir}/#{basename}"
  end

  def ssl_context
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ctx
  end

  def default_options
    @default_options ||= { ssl_context: ssl_context }
  end
end
