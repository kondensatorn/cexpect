# frozen_string_literal: true

require 'ostruct'

# TODO: Haven't figured out how to fix this
# rubocop:disable Metrics/BlockLength
RSpec.describe CExpect do
  context 'expect-style methods' do
    let(:pipe) { OpenStruct.new.tap { |os| os.reader, os.writer = IO.pipe } }
    let(:io) { described_class::Reader.new(pipe.reader) }

    let(:filename) { 'a_nice_file.name' }
    let(:output)  { "ls\r\n#{filename}\r\n\r\n> " }
    let(:timeout) { 1 }
    before { pipe.writer << output }

    describe '#fexpect' do
      let(:match_data) { io.fexpect(pattern, timeout) }

      subject { match_data }

      context 'when it matches' do
        let(:pattern) { '> ' }
        let(:before_prompt) { output.sub(pattern, '') }

        it { should eq(before_prompt) }
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
        let(:pattern) { / will not match! / }
        let(:timeout) { 0 }
        subject { match_data }

        it { is_expected.to be_nil }
      end

      context 'when it matches' do
        context 'without captures' do
          let(:pattern) { filename }
          subject { match_data[0] }

          it { should eq(filename) }
        end

        context 'with anonymous captures' do
          let(:pattern) { /(#{filename})/ }
          subject { match_data.captures.first }

          it { should eq(filename) }
        end

        context 'with named captures' do
          let(:pattern) { /(?<filename>#{filename})/ }
          subject { match_data[:filename] }

          it { should eq(filename) }
        end

        context 'with verbosity' do
          let(:pattern) { /> / }
          let(:logger_output) { +'' }
          let(:logger) { double('logger') }
          before do
            allow(logger).to receive(:update) { |c| logger_output << c }
            io.add_observer(logger)
            match_data
          end
          subject { logger_output }

          it { should include(filename) }
        end
      end

      context 'with block' do
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
        subject { match_data }

        it { is_expected.to be_kind_of(MatchData) }
      end
    end
  end

  describe '.spawn' do
    context 'without block' do
      let(:rv) { described_class.spawn('sh') }

      it 'should return values compatible with PTY.spawn' do
        psrv = PTY.spawn('sh')
        expect(rv.size).to eq(psrv.size)
        # First element delegates to returned IO
        expect(rv[0].__getobj__).to be_kind_of(psrv[0].class)
        expect(rv[1]).to be_kind_of(psrv[1].class)
        expect(rv[2]).to be_kind_of(psrv[2].class)
      end

      it 'should return a reader, implementing #expect' do
        expect(rv.first).to respond_to(:expect)
      end

      it 'should return a reader, implementing #fexpect' do
        expect(rv.first).to respond_to(:fexpect)
      end
    end

    context 'with block' do
      let(:rv) {
        described_class.spawn('sh') { |r, w, pid| { args: [r, w, pid] } }
      }

      it 'should yield as PTY.spawn, and return what the block returns' do
        psrv = nil # for scope
        PTY.spawn('sh') { |r, w, pid| psrv = [r, w, pid] }
        expect(rv).to include(:args)
        expect(rv[:args].size).to eq(psrv.size)
        # First object delegates to returned IO
        expect(rv[:args][0].__getobj__).to be_kind_of(psrv[0].class)
        expect(rv[:args][1]).to be_kind_of(psrv[1].class)
        expect(rv[:args][2]).to be_kind_of(psrv[2].class)
      end

      it 'should yield a reader that responds to #expect' do
        expect(rv[:args].first).to respond_to(:expect)
      end

      it 'should yield a reader that responds to #fexpect' do
        expect(rv[:args].first).to respond_to(:fexpect)
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
