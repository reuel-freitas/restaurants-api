require 'rails_helper'

RSpec.describe ImportCleanupService do
  let(:temp_dir) { Rails.root.join("tmp", "imports") }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '.cleanup_old_files' do
    context 'when temp directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(false)
      end

      it 'returns early without processing' do
        expect(Dir).not_to receive(:glob)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_old_files

        expect(result).to be_nil
      end
    end

    context 'when temp directory exists' do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
      end

      context 'with no files to clean up' do
        before do
          allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([])
        end

        it 'returns 0 files removed' do
          result = described_class.cleanup_old_files

          expect(result).to eq(0)
          expect(Rails.logger).to have_received(:info).with("Import cleanup completed: 0 files removed")
        end
      end

      context 'with files to clean up' do
        let(:old_file1) { File.join(temp_dir, "import_old1.csv") }
        let(:old_file2) { File.join(temp_dir, "import_old2.csv") }
        let(:new_file) { File.join(temp_dir, "import_new.csv") }

        before do
          allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file1, old_file2, new_file ])
          allow(File).to receive(:mtime).with(old_file1).and_return(26.hours.ago)
          allow(File).to receive(:mtime).with(old_file2).and_return(30.hours.ago)
          allow(File).to receive(:mtime).with(new_file).and_return(2.hours.ago)
        end

        it 'deletes only old files' do
          expect(File).to receive(:delete).with(old_file1)
          expect(File).to receive(:delete).with(old_file2)
          expect(File).not_to receive(:delete).with(new_file)

          result = described_class.cleanup_old_files

          expect(result).to eq(2)
          expect(Rails.logger).to have_received(:info).with("Import cleanup completed: 2 files removed")
        end

        it 'logs successful deletions' do
          allow(File).to receive(:delete).with(old_file1)
          allow(File).to receive(:delete).with(old_file2)

          described_class.cleanup_old_files

          expect(Rails.logger).to have_received(:info).with("Cleaned up old import file: #{old_file1}")
          expect(Rails.logger).to have_received(:info).with("Cleaned up old import file: #{old_file2}")
        end
      end

      context 'with custom hours threshold' do
        let(:custom_hours) { 48 }
        let(:old_file) { File.join(temp_dir, "import_very_old.csv") }

        before do
          allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file ])
          allow(File).to receive(:mtime).with(old_file).and_return(50.hours.ago)
        end

        it 'uses custom hours threshold' do
          expect(File).to receive(:delete).with(old_file)

          result = described_class.cleanup_old_files(custom_hours)

          expect(result).to eq(1)
        end

        it 'defaults to 24 hours when no threshold provided' do
          expect(File).to receive(:delete).with(old_file)

          result = described_class.cleanup_old_files

          expect(result).to eq(1)
        end
      end

      context 'when file deletion fails' do
        let(:old_file) { File.join(temp_dir, "import_old.csv") }
        let(:error_message) { 'Permission denied' }

        before do
          allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file ])
          allow(File).to receive(:mtime).with(old_file).and_return(26.hours.ago)
          allow(File).to receive(:delete).with(old_file).and_raise(StandardError, error_message)
        end

        it 'logs the error and continues processing' do
          expect(Rails.logger).to receive(:error).with("Failed to delete old import file #{old_file}: #{error_message}")

          result = described_class.cleanup_old_files

          expect(result).to eq(0)
          expect(Rails.logger).to have_received(:info).with("Import cleanup completed: 0 files removed")
        end

        it 'handles different error types gracefully' do
          allow(File).to receive(:delete).with(old_file).and_raise(RuntimeError, 'Runtime error')
          expect(Rails.logger).to receive(:error).with("Failed to delete old import file #{old_file}: Runtime error")

          result = described_class.cleanup_old_files

          expect(result).to eq(0)
        end
      end

      context 'with mixed success and failure scenarios' do
        let(:old_file1) { File.join(temp_dir, "import_old1.csv") }
        let(:old_file2) { File.join(temp_dir, "import_old2.csv") }
        let(:old_file3) { File.join(temp_dir, "import_old3.csv") }

        before do
          allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file1, old_file2, old_file3 ])
          allow(File).to receive(:mtime).with(old_file1).and_return(26.hours.ago)
          allow(File).to receive(:mtime).with(old_file2).and_return(30.hours.ago)
          allow(File).to receive(:mtime).with(old_file3).and_return(25.hours.ago)
        end

        it 'continues processing after individual failures' do
          allow(File).to receive(:delete).with(old_file1)
          allow(File).to receive(:delete).with(old_file2).and_raise(StandardError, 'Permission denied')
          allow(File).to receive(:delete).with(old_file3)

          expect(Rails.logger).to receive(:error).with("Failed to delete old import file #{old_file2}: Permission denied")

          result = described_class.cleanup_old_files

          expect(result).to eq(2)
          expect(Rails.logger).to have_received(:info).with("Import cleanup completed: 2 files removed")
        end
      end
    end
  end

  describe '.cleanup_file' do
    let(:test_file_path) { "/tmp/test_file.csv" }

    context 'when file_path is nil' do
      it 'returns early without processing' do
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file(nil)

        expect(result).to be_nil
      end
    end

    context 'when file_path is empty string' do
      before do
        allow(File).to receive(:exist?).with("").and_return(false)
      end

      it 'returns early without processing' do
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file("")

        expect(result).to be_nil
      end
    end

    context 'when file_path is not a string' do
      it 'returns early without processing for numbers' do
        allow(File).to receive(:exist?).with(123).and_return(false)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file(123)

        expect(result).to be_nil
      end

      it 'returns early without processing for symbols' do
        allow(File).to receive(:exist?).with(:file_path).and_return(false)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file(:file_path)

        expect(result).to be_nil
      end

      it 'returns early without processing for arrays' do
        allow(File).to receive(:exist?).with([ 'file1', 'file2' ]).and_return(false)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file([ 'file1', 'file2' ])

        expect(result).to be_nil
      end

      it 'returns early without processing for hashes' do
        allow(File).to receive(:exist?).with({ path: 'file.csv' }).and_return(false)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file({ path: 'file.csv' })

        expect(result).to be_nil
      end

      it 'returns early without processing for booleans' do
        allow(File).to receive(:exist?).with(true).and_return(false)
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file(true)

        expect(result).to be_nil
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(test_file_path).and_return(false)
      end

      it 'returns early without processing' do
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_file(test_file_path)

        expect(result).to be_nil
      end
    end

    context 'when file exists' do
      before do
        allow(File).to receive(:exist?).with(test_file_path).and_return(true)
      end

      context 'when file deletion succeeds' do
        before do
          allow(File).to receive(:delete).with(test_file_path)
        end

        it 'deletes the file successfully' do
          expect(File).to receive(:delete).with(test_file_path)

          result = described_class.cleanup_file(test_file_path)

          expect(result).to be true
        end

        it 'logs successful deletion' do
          expect(Rails.logger).to receive(:info).with("Cleaned up import file: #{test_file_path}")

          described_class.cleanup_file(test_file_path)
        end
      end

      context 'when file deletion fails' do
        let(:error_message) { 'Permission denied' }

        before do
          allow(File).to receive(:delete).with(test_file_path).and_raise(StandardError, error_message)
        end

        it 'logs the error and returns false' do
          expect(Rails.logger).to receive(:error).with("Failed to delete import file #{test_file_path}: #{error_message}")

          result = described_class.cleanup_file(test_file_path)

          expect(result).to be false
        end

        it 'handles different error types gracefully' do
          allow(File).to receive(:delete).with(test_file_path).and_raise(RuntimeError, 'Runtime error')
          expect(Rails.logger).to receive(:error).with("Failed to delete import file #{test_file_path}: Runtime error")

          result = described_class.cleanup_file(test_file_path)

          expect(result).to be false
        end

        it 'handles NoMethodError gracefully' do
          allow(File).to receive(:delete).with(test_file_path).and_raise(NoMethodError, 'Method not found')
          expect(Rails.logger).to receive(:error).with("Failed to delete import file #{test_file_path}: Method not found")

          result = described_class.cleanup_file(test_file_path)

          expect(result).to be false
        end

        it 'handles SystemCallError gracefully' do
          allow(File).to receive(:delete).with(test_file_path).and_raise(Errno::EACCES, 'Permission denied')
          expect(Rails.logger).to receive(:error).with("Failed to delete import file #{test_file_path}: Permission denied - Permission denied")

          result = described_class.cleanup_file(test_file_path)

          expect(result).to be false
        end
      end
    end
  end

  describe 'integration scenarios' do
    context 'complete cleanup_old_files flow' do
      let(:old_file1) { File.join(temp_dir, "import_old1.csv") }
      let(:old_file2) { File.join(temp_dir, "import_old2.csv") }
      let(:new_file) { File.join(temp_dir, "import_new.csv") }

      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file1, old_file2, new_file ])
        allow(File).to receive(:mtime).with(old_file1).and_return(25.hours.ago)
        allow(File).to receive(:mtime).with(old_file2).and_return(26.hours.ago)
        allow(File).to receive(:mtime).with(new_file).and_return(2.hours.ago)
      end

      it 'executes the complete flow successfully' do
        expect(File).to receive(:delete).with(old_file1)
        expect(File).to receive(:delete).with(old_file2)
        expect(File).not_to receive(:delete).with(new_file)

        expect(Rails.logger).to receive(:info).with("Cleaned up old import file: #{old_file1}")
        expect(Rails.logger).to receive(:info).with("Cleaned up old import file: #{old_file2}")
        expect(Rails.logger).to receive(:info).with("Import cleanup completed: 2 files removed")

        result = described_class.cleanup_old_files

        expect(result).to eq(2)
      end
    end

    context 'complete cleanup_file flow' do
      let(:test_file_path) { "/tmp/test_file.csv" }

      before do
        allow(File).to receive(:exist?).with(test_file_path).and_return(true)
        allow(File).to receive(:delete).with(test_file_path)
      end

      it 'executes the complete flow successfully' do
        expect(Rails.logger).to receive(:info).with("Cleaned up import file: #{test_file_path}")

        result = described_class.cleanup_file(test_file_path)

        expect(result).to be true
      end
    end

    context 'mixed success and failure scenarios' do
      let(:old_file1) { File.join(temp_dir, "import_old1.csv") }
      let(:old_file2) { File.join(temp_dir, "import_old2.csv") }
      let(:old_file3) { File.join(temp_dir, "import_old3.csv") }

      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ old_file1, old_file2, old_file3 ])
        allow(File).to receive(:mtime).with(old_file1).and_return(25.hours.ago)
        allow(File).to receive(:mtime).with(old_file2).and_return(26.hours.ago)
        allow(File).to receive(:mtime).with(old_file3).and_return(27.hours.ago)
      end

      it 'handles mixed success and failure gracefully' do
        allow(File).to receive(:delete).with(old_file1)
        allow(File).to receive(:delete).with(old_file2).and_raise(StandardError, 'Permission denied')
        allow(File).to receive(:delete).with(old_file3)

        expect(Rails.logger).to receive(:info).with("Cleaned up old import file: #{old_file1}")
        expect(Rails.logger).to receive(:error).with("Failed to delete old import file #{old_file2}: Permission denied")
        expect(Rails.logger).to receive(:info).with("Cleaned up old import file: #{old_file3}")
        expect(Rails.logger).to receive(:info).with("Import cleanup completed: 2 files removed")

        result = described_class.cleanup_old_files

        expect(result).to eq(2)
      end
    end
  end

  describe 'edge cases and boundary conditions' do
    context 'with very old files' do
      let(:very_old_file) { File.join(temp_dir, "import_very_old.csv") }

      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ very_old_file ])
        allow(File).to receive(:mtime).with(very_old_file).and_return(1000.hours.ago)
      end

      it 'handles very old files correctly' do
        expect(File).to receive(:delete).with(very_old_file)

        result = described_class.cleanup_old_files

        expect(result).to eq(1)
      end
    end

    context 'with files just older than cutoff time' do
      let(:just_old_file) { File.join(temp_dir, "import_old.txt") }

      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ just_old_file ])
        allow(File).to receive(:mtime).with(just_old_file).and_return(24.hours.ago - 1.second)
      end

      it 'deletes files just older than cutoff time' do
        expect(File).to receive(:delete).with(just_old_file)

        result = described_class.cleanup_old_files

        expect(result).to eq(1)
      end
    end

    context 'with files just older than cutoff time' do
      let(:just_old_file) { File.join(temp_dir, "import_old.csv") }

      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([ just_old_file ])
        allow(File).to receive(:mtime).with(just_old_file).and_return(24.hours.ago - 1.second)
      end

      it 'deletes files just older than cutoff time' do
        expect(File).to receive(:delete).with(just_old_file)

        result = described_class.cleanup_old_files

        expect(result).to eq(1)
      end
    end

    context 'with custom hours threshold edge cases' do
      it 'handles 0 hours threshold' do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([])

        result = described_class.cleanup_old_files(0)

        expect(result).to eq(0)
      end

      it 'handles negative hours threshold' do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([])

        result = described_class.cleanup_old_files(-5)

        expect(result).to eq(0)
      end

      it 'handles very large hours threshold' do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(temp_dir, "import_*")).and_return([])

        result = described_class.cleanup_old_files(999999)

        expect(result).to eq(0)
      end
    end
  end
end
