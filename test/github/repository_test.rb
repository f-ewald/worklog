# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/repository'

class GithubRepositoryTest < Minitest::Test
  include Worklog::Github

  def test_repository_init
    repo = Repository.new(owner: 'owner', name: 'repository')

    assert_equal 'owner', repo.owner
    assert_equal 'repository', repo.name
  end

  def test_repository_from_url
    test_cases = [
      ['https://github.com/owner/repository', Repository.new(owner: 'owner', name: 'repository')],
      ['owner/repository', Repository.new(owner: 'owner', name: 'repository')],
      ['https://example.com/owner/repository.git', nil]
    ]

    test_cases.each do |url, expected|
      r = Repository.from_url(url)

      assert_equal expected, r
      assert_equal 'owner/repository', r.to_s unless r.nil?
    end
  end
end
