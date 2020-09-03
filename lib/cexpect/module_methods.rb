# frozen_string_literal: true

require 'pty'

module CExpect
  #
  # Module methods for CExpect
  #
  module ModuleMethods
    #
    # Assume first element benefits from using CExpect
    #
    # This generalization is a bit iffy; it works for class methods
    # that returns and yields an IO reader first, followed by any
    # other parameters. But hey, if we need to wrap things that behave
    # differently, we can just give this one (and its shared examples
    # in the specs) a more specific name and implement another.
    #
    def cexpect_wrap(array, &block)
      array[0] = CExpect::Reader.new(array[0])
      if block_given?
        block.call(*array)
      else
        array
      end
    end

    def pipe(*args, &block)
      cexpect_wrap(IO.pipe(*args), &block)
    end

    def spawn(*args, &block)
      cexpect_wrap(PTY.spawn(*args), &block)
    end
  end
end
