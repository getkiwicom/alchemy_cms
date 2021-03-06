require 'spec_helper'

describe Alchemy::Admin::EssencesHelper do
  include Alchemy::Admin::ElementsHelper

  let(:element) do
    create(:element, name: 'article', create_contents_after_create: true)
  end

  describe 'essence rendering' do
    before do
      if element
        element.content_by_name('intro').essence.update(body: 'hello!')
      end
    end

    describe '#render_essence_editor' do
      it "should render an essence editor" do
        content = element.content_by_name('intro')
        expect(helper.render_essence_editor(content)).
          to match(/input.+type="text".+value="hello!/)
      end
    end

    describe '#render_essence_editor_by_name' do
      subject { render_essence_editor_by_name(element, content) }

      let(:content) { 'intro' }

      it "renders an essence editor by given name" do
        is_expected.to match(/input.+type="text".+value="hello!/)
      end

      context 'when element is nil' do
        let(:element) { nil }

        it "displays a warning" do
          is_expected.to have_selector(".content_editor_error")
          is_expected.to have_content("No element given.")
        end
      end

      context 'when content is not found on element' do
        let(:content) { 'sputz' }

        it "displays a warning" do
          is_expected.to have_selector(".content_editor.missing")
        end
      end
    end
  end

  describe '#pages_for_select' do
    let(:contact_form) do
      create(:element, name: 'contactform', create_contents_after_create: true)
    end

    let(:page_a) { create(:public_page, name: 'Page A') }
    let(:page_b) { create(:public_page, name: 'Page B') }
    let(:page_c) { create(:public_page, name: 'Page C', parent_id: page_b.id) }

    before do
      # to be shure the ordering is alphabetic
      page_b
      page_a
      helper.session[:alchemy_language_id] = 1
    end

    context "with no arguments given" do
      it "should return options for select with all pages ordered by lft" do
        expect(helper.pages_for_select).to match(/option.*Page B.*Page A/m)
      end

      it "should return options for select with nested page names" do
        page_c
        output = helper.pages_for_select
        expect(output).to match(/option.*Startseite.*>&nbsp;&nbsp;Page B.*>&nbsp;&nbsp;&nbsp;&nbsp;Page C.*>&nbsp;&nbsp;Page A/m)
      end
    end

    context "with pages passed in" do
      before do
        @pages = []
        3.times { @pages << create(:public_page) }
      end

      it "should return options for select with only these pages" do
        output = helper.pages_for_select(@pages)
        expect(output).to match(/#{@pages.collect(&:name).join('.*')}/m)
        expect(output).not_to match(/Page A/m)
      end

      it "should not nest the page names" do
        output = helper.pages_for_select(@pages)
        expect(output).not_to match(/option.*&nbsp;/m)
      end
    end
  end

  describe '#essence_picture_thumbnail' do
    let(:content) { build_stubbed(:content, essence: build_stubbed(:essence_picture)) }

    it "should return an image tag" do
      expect(helper.essence_picture_thumbnail(content, {})).to have_selector('img[src]')
    end

    context 'when given content has no ingredient' do
      before { allow(content).to receive(:ingredient).and_return(nil) }

      it "should return nil" do
        expect(helper.essence_picture_thumbnail(content, {})).to eq(nil)
      end
    end

    context 'when the picture given has a size of 140x169 and it should be cropped to 250x250' do
      before do
        allow(content.essence).to receive(:image_file_width).and_return(140)
        allow(content.essence).to receive(:image_file_height).and_return(169)
      end

      it 'the thumbnail url should contain 77 and 93 as thumbnail width and height' do
        expect(helper.essence_picture_thumbnail(content, {image_size: "250x250", crop: true})).to match(/77x93/)
      end

      it 'the thumbnail url should contain 77 and 93 as thumbnail width and height' do
        expect(helper.essence_picture_thumbnail(content, {image_size: "250x250"})).to match(/77x93/)
      end
    end

    context 'when the picture given has a size of 300x50 and it should be cropped/resized to 225x175' do
      before do
        allow(content.essence).to receive(:image_file_width).and_return(300)
        allow(content.essence).to receive(:image_file_height).and_return(50)
      end

      it 'the thumbnail url should contain 111x25 as thumbnail width and height' do
        expect(helper.essence_picture_thumbnail(content, { size: "225x175", crop: true})).to match(/111x25/)
      end

      it 'the thumbnail url should contain 111x19 as thumbnail width and height' do
        expect(helper.essence_picture_thumbnail(content, { size: "225x175"})).to match(/111x19/)
      end
    end
  end

  describe "#edit_picture_dialog_size" do
    let(:content) { build_stubbed(:content) }

    subject { edit_picture_dialog_size(content) }

    context "with content having setting caption_as_textarea being true and sizes set" do
      before do
        allow(content).to receive(:settings) do
          {
            caption_as_textarea: true,
            sizes: ['100x100', '200x200']
          }
        end

        it { is_expected.to eq("380x320") }
      end
    end

    context "with content having setting caption_as_textarea being true and no sizes set" do
      before do
        allow(content).to receive(:settings) do
          {
            caption_as_textarea: true
          }
        end

        it { is_expected.to eq("380x300") }
      end
    end

    context "with content having setting caption_as_textarea being false and sizes set" do
      before do
        allow(content).to receive(:settings) do
          {
            caption_as_textarea: false,
            sizes: ['100x100', '200x200']
          }
        end

        it { is_expected.to eq("380x290") }
      end
    end

    context "with content having setting caption_as_textarea being false and no sizes set" do
      before do
        allow(content).to receive(:settings) do
          {
            caption_as_textarea: false
          }
        end

        it { is_expected.to eq("380x255") }
      end
    end
  end
end
