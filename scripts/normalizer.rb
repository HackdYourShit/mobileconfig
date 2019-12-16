# frozen_string_literal: true

class Normalizer
  HEAD = /<\?(xml|XML)/.freeze
  TAIL = %r{</(plist|PLIST)}.freeze

  def normalize_all
    signed_mobileconfig_files.each do |file|
      normalize file
    rescue StandardError => e
      puts "Failed to normalize #{file} (#{e})"
    end
  end

  private

  def save(file, body)
    basename = File.basename(file)
    name = basename.split(".")[0..-2].join(".")
    new_filename = "#{name}.plain.mobileconfig"
    path = file.sub(basename, new_filename)
    File.open(path, "w") { |f| f.write body }
  end

  def normalize(file)
    lines = File.readlines(file).map { |line| line.force_encoding("utf-8").scrub.chomp }

    head = lines.index { |line| HEAD.match? line }
    tail = lines.index { |line| TAIL.match? line }

    if head.nil? || tail.nil?
      puts "Failed to normalize #{file}"
      return
    end

    body = [
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      lines[(head + 1)...tail],
      "</plist>"
    ].flatten.join("\n")

    save file, body
  end

  def mobileconfig_files
    Dir.glob(File.expand_path("../samples/*/*.mobileconfig", __dir__))
  end

  def signed_mobileconfig_files
    mobileconfig_files.reject do |file|
      signed_mobileconfig? file
    end
  end

  def signed_mobileconfig?(file)
    data = File.read(file)
    first = data.lines.first
    HEAD.match? first
  rescue ArgumentError => _e
    false
  end
end

normalizer = Normalizer.new
normalizer.normalize_all
