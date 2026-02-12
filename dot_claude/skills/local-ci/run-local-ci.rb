#!/usr/bin/env ruby
# frozen_string_literal: true

# Local CI Runner
# Reads tests from tmp/local-ci-tests.txt, runs them, removes passing tests.
# Run repeatedly until the file is empty.

require 'json'
require 'fileutils'
require 'open3'

TEST_LIST = 'tmp/local-ci-tests.txt'
RSPEC_RESULTS = 'tmp/local-ci-rspec-results.json'

def main
  unless File.exist?(TEST_LIST)
    puts "No test list found at #{TEST_LIST}"
    exit 0
  end

  tests = File.readlines(TEST_LIST, chomp: true).reject(&:empty?)

  if tests.empty?
    puts "✓ All tests passing! Test list is empty."
    exit 0
  end

  rspec_tests = tests.select { |t| t.start_with?('spec/') }
  jest_tests = tests.select { |t| t.match?(/\.(spec|test)\.(js|jsx|ts|tsx)$/) }

  failed_tests = []

  failed_tests += run_rspec(rspec_tests) if rspec_tests.any?
  failed_tests += run_jest(jest_tests) if jest_tests.any?

  # Rewrite test list with only failures
  File.write(TEST_LIST, failed_tests.join("\n") + (failed_tests.any? ? "\n" : ""))

  if failed_tests.empty?
    puts "\n✓ All tests passing! Test list is now empty."
  else
    puts "\n#{failed_tests.size} test(s) still failing. Run again after fixing."
  end
end

def run_rspec(tests)
  return [] if tests.empty?

  puts "Running #{tests.size} RSpec test(s)..."

  use_parallel = system('which parallel_rspec > /dev/null 2>&1') && tests.size > 1

  if use_parallel
    run_parallel_rspec(tests)
  else
    run_standard_rspec(tests)
  end
end

def run_standard_rspec(tests)
  cmd = [
    'bundle', 'exec', 'rspec',
    '--format', 'json', '--out', RSPEC_RESULTS,
    '--format', 'progress',
    *tests
  ]

  system(*cmd)
  parse_rspec_failures
end

def run_parallel_rspec(tests)
  # parallel_rspec doesn't support --format json directly to aggregate
  # So we run it for speed, then re-run failures with json output

  cmd = ['bundle', 'exec', 'parallel_rspec', *tests]
  system(*cmd)

  return [] if $?.success?

  # Re-run with rspec to get JSON output of failures
  puts "Re-running to capture failure details..."
  run_standard_rspec(tests)
end

def parse_rspec_failures
  return [] unless File.exist?(RSPEC_RESULTS)

  begin
    results = JSON.parse(File.read(RSPEC_RESULTS))
    failed_files = results['examples']
      .select { |e| e['status'] == 'failed' }
      .map { |e| e['file_path'].sub(%r{^\./}, '') }
      .uniq

    failed_files
  rescue JSON::ParserError => e
    puts "Warning: Could not parse RSpec results: #{e.message}"
    []
  end
end

def run_jest(tests)
  return [] if tests.empty?

  puts "Running #{tests.size} Jest test(s)..."

  cmd = ['yarn', 'jest', '--json', '--outputFile=tmp/local-ci-jest-results.json', *tests]
  system(*cmd)

  parse_jest_failures
end

def parse_jest_failures
  results_file = 'tmp/local-ci-jest-results.json'
  return [] unless File.exist?(results_file)

  begin
    results = JSON.parse(File.read(results_file))
    results['testResults']
      .select { |r| r['status'] == 'failed' }
      .map { |r| r['name'].sub(%r{^.*/}, '') }
  rescue JSON::ParserError => e
    puts "Warning: Could not parse Jest results: #{e.message}"
    []
  end
end

main
