# mobileconfig in the wild

A collection of .mobileconfig in the wild.

## Prerequisites

- Ruby: `~> 2.6`
- Bundler: `~> 2.0`

## Installation

```bash
git clone https://github.com/ninoseki/mobileconfig.git
cd mobileconfig
bundle
```

## Usage

### Crawl & collect .mobileconfig from URLs

Create a plain text file which contains an IP address per line.

```bash
bundle exec ruby crawler.rb /path/to/file.txt
```

This script crawls IP addresses and collects .mobileconfig from the addresses.

Collected .mobileconfig files are saved in `./samples`.
