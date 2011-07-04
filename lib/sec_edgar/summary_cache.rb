module SecEdgar

  class SummaryCache
    SUMMARY_CACHE_FOLDER = '/Users/jimlindstrom/code/sec_edgar/summarycache/'

    def initialize
    end

    def exists?(key)
      return FileTest.exists?(key_to_cache_filename(key))
    end

    def insert(key, value)
      value.write_to_yaml(key_to_cache_filename(key))
    end

    def lookup(key)
      summary = FinancialStatementSummary.new
      summary.read_from_yaml(key_to_cache_filename(key))
      return summary
    end

    def key_to_cache_filename(key)
      return SUMMARY_CACHE_FOLDER + Digest::SHA1.hexdigest(key) + ".yaml"
    end

  end

end
