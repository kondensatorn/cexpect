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
  describe '.spawn' do
    context 'without block' do
      let(:rv) { described_class.spawn('sh') }

      it 'returns values compatible with PTY.spawn' do
        psrv = PTY.spawn('sh')
        expect(rv.size).to eq(psrv.size)
        # First element delegates to returned IO
        expect(rv[0].__getobj__).to be_kind_of(psrv[0].class)
        expect(rv[1]).to be_kind_of(psrv[1].class)
        expect(rv[2]).to be_kind_of(psrv[2].class)
      end

      it 'returns a reader, implementing #expect' do
        expect(rv.first).to respond_to(:expect)
      end

      it 'returns a reader, implementing #fexpect' do
        expect(rv.first).to respond_to(:fexpect)
      end
    end

    context 'with block' do
      let(:rv) do
        described_class.spawn('sh') { |r, w, pid| { args: [r, w, pid] } }
      end

      let(:pty_spawn_rv) do
        psrv = [] # for scope
        PTY.spawn('sh') { |r, w, pid| psrv.push(r, w, pid) }
        psrv
      end

      it 'yields as PTY.spawn, and returns what the block returns' do
        expect(rv[:args].size).to eq(pty_spawn_rv.size)
        # First object delegates to returned IO
        expect(rv[:args][0].__getobj__).to be_kind_of(pty_spawn_rv[0].class)
        expect(rv[:args][1]).to be_kind_of(pty_spawn_rv[1].class)
        expect(rv[:args][2]).to be_kind_of(pty_spawn_rv[2].class)
      end

      it 'yields a reader that responds to #expect' do
        expect(rv[:args].first).to respond_to(:expect)
      end

      it 'yields a reader that responds to #fexpect' do
        expect(rv[:args].first).to respond_to(:fexpect)
      end
    end
  end
  # rubocop: enable RSpec/MultipleExpectations
end

# rubocop:enable Metrics/BlockLength
