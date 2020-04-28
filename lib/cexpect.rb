require 'delegate'
require 'observer'
require 'pty'

module CExpect
  def self.spawn(*args)
    original_rd, wr, pid = PTY.spawn(*args)
    rd = CExpect::Reader.new(original_rd)
    if block_given?
      yield(rd, wr, pid)
    else
      [rd, wr, pid]
    end
  end

  class Reader < SimpleDelegator
    include Observable

    def initialize(_original)
      @leftovers = ''
      super
    end

    def expect(pat, timeout = nil, match_method: :_expect_re_match)
      buf = +''

      result = catch(:result) do
        loop { _expect_try(pat, buf, timeout, match_method) }
      end

      if block_given?
        yield result
      else
        result
      end
    end

    def fexpect(pat, timeout = nil)
      expect(pat, timeout, match_method: :_expect_string_match)
    end

    private

    def _expect_try(pat, buf, timeout, match_method)
      c = _expect_getc(timeout)

      if c.nil?
        @leftovers = buf
        throw(:result, nil)
      end

      buf << c

      _expect_log(pat, buf)

      result = send(match_method, buf, pat)
      throw(:result, result) if result
    end

    def _expect_getc(timeout)
      return @leftovers.slice!(0).chr unless @leftovers.empty?

      return nil if !IO.select([self], nil, nil, timeout) || eof?

      getc.chr
    end

    def _expect_log(pat, buf)
      return if count_observers.zero?

      changed
      notify_observers("pat: #{pat.inspect}\nbuf: #{buf.inspect}\n")
    end

    def _expect_re_match(buf, pat)
      buf.match(pat)
    end

    def _expect_string_match(buf, pat)
      buf[0, buf.size - pat.size] if buf.end_with?(pat)
    end
  end
end
