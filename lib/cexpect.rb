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
    def initialize(io, observers = nil)
      extend(LoggingReader) if observers
      super(io)
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

      throw(:result, nil) if c.nil?

      buf << c

      log(pat, buf) if respond_to?(:log)

      result = send(match_method, buf, pat)
      throw(:result, result) if result
    end

    def getc(timeout)
      rd = __getobj__

      return nil if !IO.select([rd], nil, nil, timeout) || eof?

      rd.getc.chr
    end

    def re_match(buf, pat)
      buf.match(pat)
    end

    def string_match(buf, pat)
      buf[0, buf.size - pat.size] if buf.end_with?(pat)
    end
  end

  #
  # Adds logging capability when observers are given to constructor
  #
  module LoggingReader
    include Observable

    def log(pat, buf)
      return if count_observers.zero?

      changed
      notify_observers(pat, buf)
    end
  end
end
