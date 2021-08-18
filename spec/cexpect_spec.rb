# frozen_string_literal: true

require 'ostruct'

# TODO: Haven't figured out how to fix this
# rubocop:disable Metrics/BlockLength
RSpec.describe CExpect do
  describe 'expect-style methods' do
    let(:pipe) { OpenStruct.new.tap { |os| os.reader, os.writer = IO.pipe } }
    let(:io) { described_class::Reader.new(pipe.reader) }

    let(:filename) { 'a_nice_file.name' }
    let(:output)  { "ls\r\n#{filename}\r\n\r\n> " }
    let(:timeout) { 1 }

    before { pipe.writer << output }

    describe '#fexpect' do
      subject { match_data }

      let(:match_data) { io.fexpect(pattern, timeout) }

      context 'when it matches' do
        let(:pattern) { '> ' }
        let(:before_prompt) { output.sub(pattern, '') }

        it { is_expected.to eq(before_prompt) }
      end

      context 'when it times out' do
        let(:timeout) { 0 }
        let(:pattern) { "This won't match" }

        it { is_expected.to be_nil }
      end
    end

    describe '#expect' do
      let(:match_data) { io.expect(pattern, timeout) }

      context 'when it times out' do
        subject { match_data }

        let(:pattern) { / will not match! / }
        let(:timeout) { 0 }

        it { is_expected.to be_nil }
      end

      context 'when it matches' do
        context 'without captures' do
          subject { match_data[0] }

          let(:pattern) { filename }

          it { is_expected.to eq(filename) }
        end

        context 'with anonymous captures' do
          subject { match_data.captures.first }

          let(:pattern) { /(#{filename})/ }

          it { is_expected.to eq(filename) }
        end

        context 'with named captures' do
          subject { match_data[:filename] }

          let(:pattern) { /(?<filename>#{filename})/ }

          it { is_expected.to eq(filename) }
        end

        context 'with verbosity' do
          subject { logger_output }

          let(:pattern) { /> / }
          let(:logger_output) { +'' }
          let(:logger) { double('logger') }
          let(:io) do
            described_class::Reader.new(pipe.reader).tap do |obj|
              obj.add_observer(logger)
            end
          end

          before do
            allow(logger).
              to receive(:update) { |_pat, buf| logger_output << buf }
            io.add_observer(logger)
            match_data
          end

          it { is_expected.to include(filename) }
        end
      end

      context 'with block' do
        subject { match_data }

        let(:pattern) { /> / }
        # Add a check that the block is really run
        let(:checker) { double }
        let(:match_data) do
          io.expect(pattern, timeout) do |md|
            checker.check
            md
          end
        end

        before { expect(checker).to receive(:check) }

        it { is_expected.to be_kind_of(MatchData) }
      end
    end
  end

  # rubocop: disable RSpec/MultipleExpectations
  shared_examples 'wrapper function' do |wrapped_class, method, extra_args|
    context 'without block' do
      let(:rv) { described_class.send(method, *extra_args) }
      let(:wrapped_rv) { wrapped_class.send(method, *extra_args) }

      it 'returns values compatible with wrapped method' do
        expect(rv.size).to eq(wrapped_rv.size)
        expect(rv.first.__getobj__).to be_kind_of(wrapped_rv.first.class)
        rv[1..-1].zip(wrapped_rv[1..-1]).each do |a, b|
          expect(a).to be_kind_of(b.class)
        end
      end

      it 'returns a CExpect::Reader as its first value' do
        expect(rv.first).to be_kind_of(CExpect::Reader)
      end
    end

    context 'with block' do
      let(:rv) { described_class.send(method) { |*args| { args: args } } }
      let(:wrapped_rv) do
        # Wrapped method may not return the return value of the block
        wrv = []
        wrapped_class.send(method) { |*args| wrv.push(*args.flatten) }
        wrv
      end

      it 'yields as wrapped method, and returns what the block returns' do
        expect(rv[:args].size).to eq(wrapped_rv.size)
        expect(rv[:args].first.__getobj__).to be_kind_of(wrapped_rv.first.class)
        rv[:args][1..-1].zip(wrapped_rv[1..-1]).each do |r, wr|
          expect(r).to be_kind_of(wr.class)
        end
      end

      it 'yields a CExpect::Reader as first parameter' do
        expect(rv[:args].first).to be_kind_of(CExpect::Reader)
      end
    end
  end

  describe '.pipe' do
    it_behaves_like 'wrapper function', IO, :pipe, []
  end

  describe '.spawn' do
    it_behaves_like 'wrapper function', PTY, :spawn, ['sh']
  end
  # rubocop: enable RSpec/MultipleExpectations
end

# rubocop:enable Metrics/BlockLength
