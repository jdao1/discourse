require 'rails_helper'

RSpec.describe UploadCreator do
  let(:user) { Fabricate(:user) }

  describe '#create_for' do
    describe 'avatars & gravatars' do
      let(:user) { Fabricate(:user) }
      let(:file) { file_from_fixtures("logo.png") }

      it 'sets the user_avatar.custom_upload_id when type is "avatar"' do
        expect {
          UploadCreator.new(file, "avatar.png", type: "avatar").create_for(user.id)
        }.to change { Upload.count }.by(1)

        expect(user.reload.user_avatar.custom_upload_id).to eq(Upload.last.id)
        expect(user.reload.user_avatar.gravatar_upload_id).to eq(nil)
      end

      it 'sets the user_avatar.gravatar_upload_id when type is "gravatar"' do
        expect {
          UploadCreator.new(file, "gravatar.png", type: "gravatar").create_for(user.id)
        }.to change { Upload.count }.by(1)

        expect(user.reload.user_avatar.gravatar_upload_id).to eq(Upload.last.id)
        expect(user.reload.user_avatar.custom_upload_id).to eq(nil)
      end
    end

    describe 'when type is "gravatar"' do
      it 'sets the user_avatar' do

      end
    end

    describe 'when upload is not an image' do
      before do
        SiteSetting.authorized_extensions = 'txt'
      end

      let(:filename) { "utf-8.txt" }
      let(:file) { file_from_fixtures(filename, "encodings") }

      it 'should store the upload with the right extension' do
        expect do
          UploadCreator.new(file, "utf-8\n.txt").create_for(user.id)
        end.to change { Upload.count }.by(1)

        upload = Upload.last

        expect(upload.extension).to eq('txt')
        expect(File.extname(upload.url)).to eq('.txt')
        expect(upload.original_filename).to eq('utf-8.txt')
      end
    end

    describe 'when image has the wrong extension' do
      let(:filename) { "png_as.bin" }
      let(:file) { file_from_fixtures(filename) }

      it 'should store the upload with the right extension' do
        expect do
          UploadCreator.new(file, filename,
            force_optimize: true,
            type: UploadCreator::TYPES_TO_CROP.first
          ).create_for(user.id)
        end.to change { Upload.count }.by(1)

        upload = Upload.last

        expect(upload.extension).to eq('png')
        expect(File.extname(upload.url)).to eq('.png')
        expect(upload.original_filename).to eq('png_as.png')
      end

      describe 'for webp format' do
        before do
          SiteSetting.authorized_extensions = '.webp|.bin'
        end

        let(:filename) { "webp_as.bin" }
        let(:file) { file_from_fixtures(filename) }

        it 'should not correct the coerce filename' do
          expect do
            UploadCreator.new(file, filename).create_for(user.id)
          end.to change { Upload.count }.by(1)

          upload = Upload.last

          expect(upload.extension).to eq('bin')
          expect(File.extname(upload.url)).to eq('.bin')
          expect(upload.original_filename).to eq('webp_as.bin')
        end
      end
    end

    describe 'converting to jpeg' do
      let(:filename) { "logo.png" }
      let(:file) { file_from_fixtures(filename) }

      before do
        SiteSetting.png_to_jpg_quality = 1
      end

      it 'should store the upload with the right extension' do
        expect do
          UploadCreator.new(file, filename,
            pasted: true,
            force_optimize: true
          ).create_for(user.id)
        end.to change { Upload.count }.by(1)

        upload = Upload.last

        expect(upload.extension).to eq('jpeg')
        expect(File.extname(upload.url)).to eq('.jpeg')
        expect(upload.original_filename).to eq('logo.jpg')
      end
    end
  end
end
