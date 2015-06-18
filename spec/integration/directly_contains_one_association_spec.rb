require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class PageImage < ActiveFedora::Base
      directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles"), class_name:"FileWithMetadata"
      directly_contains_one :primary_file, through: :files, type: ::RDF::URI.new("http://example.com/primaryFile"), class_name:"FileWithMetadata"
      directly_contains_one :special_versioned_file, through: :files, type: ::RDF::URI.new("http://example.com/featuredFile"), class_name:'VersionedFileWithMetadata'
    end

    class FileWithMetadata < ActiveFedora::File
      include ActiveFedora::WithMetadata
    end
    class VersionedFileWithMetadata < ActiveFedora::File
      include ActiveFedora::WithMetadata
      has_many_versions
    end
  end

  after do
    Object.send(:remove_const, :PageImage)
    Object.send(:remove_const, :FileWithMetadata)
    Object.send(:remove_const, :VersionedFileWithMetadata)
  end

  let(:page_image)              { PageImage.create }
  let(:reloaded_page_image)     { PageImage.find(page_image.id) }

  let(:a_file)                  { page_image.files.build }
  let(:primary_file)            { page_image.build_primary_file }
  let(:special_versioned_file)  { page_image.build_special_versioned_file }
  let(:primary_sub_image)       { page_image.build_primary_sub_image }


  context "#build" do
    context "when container element is a type of ActiveFedora::File" do
      before do
        primary_file.content = "I'm in a container all alone!"
        page_image.save!
      end
      subject { reloaded_page_image.primary_file }
      it "initializes an object within the container" do
        expect(subject.content).to eq("I'm in a container all alone!")
        expect(subject.metadata_node.type).to include( ::RDF::URI.new("http://example.com/primaryFile") )
      end
      it "relies on info from the :through association, including class_name" do
        expect(page_image.files).to include(primary_file)
        expect(primary_file.uri).to include("/files/")
        expect(subject.class).to eq FileWithMetadata
      end
    end
  end

  context "finder" do
    subject { reloaded_page_image.primary_file }
    context "when no matching child is set" do
      before { page_image.files.build}
      it { is_expected.to be_nil }
    end
    context "when a matching object is directly contained" do
      before do
        a_file.content = "I'm a file"
        primary_file.content = "I am too"
        page_image.save!
      end
      it "returns the matching object" do
        expect(subject).to eq primary_file
      end
    end
    context "if class_name is set" do
      before do
        a_file.content = "I'm a file"
        special_versioned_file.content = "I am too"
        page_image.save!
      end
      subject { reloaded_page_image.special_versioned_file }
      it "uses the specified class to load objects" do
        expect(subject).to eq special_versioned_file
        expect(subject).to be_instance_of VersionedFileWithMetadata
      end
    end
  end

  describe "setter" do
    before do
      a_file.content = "I'm a file"
      primary_file.content = "I am too"
      page_image.save!
    end
    subject { reloaded_page_image.files }
    it "replaces existing record without disturbing the other contents of the container" do
      pending "Blocked by projecthydra/active_fedora#794 Can't remove objects from a ContainerAssociation"
      replacement_file = page_image.primary_file = FileWithMetadata.new
      replacement_file.content = "I'm a replacement"
      page_image.save
      expect(subject).to_not include(primary_file)
      expect(subject).to eq([a_file, replacement_file])
      expect(reloaded_page_image.primary_file).to eq(replacement_file)
    end

  end

end
