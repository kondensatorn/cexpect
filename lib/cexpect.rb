# frozen_string_literal: true

require 'cexpect/module_methods'
require 'delegate'
require 'observer'

#
# A module for supplying a different expect method
#
module CExpect
  extend CExpect::ModuleMethods

  #
  # A class delegating normal operations to a wrapped IO, adding an
  # expect method
  #
  class Reader < SimpleDelegator
    include Observable

    def initialize(_original)
      @leftovers = ''
      super
    end

    def expect(pat, timeout = nil, match_method: :re_match)
      buf = +''

      result = catch(:result) do
        loop { expect_try(pat, buf, timeout, match_method) }
      end

      if block_given?
        yield result
      else
        result
      end
    end

    def fexpect(pat, timeout = nil)
      expect(pat, timeout, match_method: :string_match)
    end

    private

    def expect_try(pat, buf, timeout, match_method)
      c = getc(timeout)

      if c.nil?
        @leftovers = buf
        throw(:result, nil)
      end

      buf << c

      log(pat, buf)

      result = send(match_method, buf, pat)
      throw(:result, result) if result
    end

    def getc(timeout)
      return @leftovers.slice!(0).chr unless @leftovers.empty?

      rd = __getobj__

      return nil if !IO.select([rd], nil, nil, timeout) || eof?

      rd.getc.chr
    end

    def log(pat, buf)
      return if count_observers.zero?

      changed
      notify_observers(pat, buf)
    end

    def re_match(buf, pat)
      buf.match(pat)
    end

    def string_match(buf, pat)
      buf[0, buf.size - pat.size] if buf.end_with?(pat)
    end
  end
end
