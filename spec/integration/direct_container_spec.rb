require 'spec_helper'

describe "Direct containers" do
  describe "#directly_contains" do
    context "when contained elements are kinds of ActiveFedora::Base" do
      before do
        class FooHistory < ActiveFedora::Base
          directly_contains :sub_histories, has_member_relation: ::RDF::URI.new("http://example.com/hasSubHistories"), class_name:"FooHistory"
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end
      let(:subhistory) { o.sub_histories.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no elements" do
        let(:o) { FooHistory.new }
        subject { o.sub_histories }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when 1..* elements exist" do
        let(:o) { FooHistory.create }
        before do
          subhistory.label = "I'm a subhistory"
          o.save
        end
        describe "#first" do
          subject { reloaded.sub_histories.first }
          it "has the content" do
            expect(subject.label).to eq 'HMMM'
          end
        end

        describe "#to_a" do
          subject { reloaded.sub_histories }
          it "has the content" do
            expect(subject.to_a).to eq [sub_history]
          end
        end

        describe "#append" do
          let(:subhistory2) { o.sub_histories.build }
          it "has two files" do
            expect(o.sub_histories).to eq [sub_history, sub_history2]
          end

          context "and then saved/reloaded" do
            before do
              sub_history2.label = "Derp"
              o.save!
            end
            it "has two files" do
              expect(reloaded.sub_histories).to eq [sub_history, sub_history2]
            end
          end
        end
      end
    end

    context "when contained elements are instances of ActiveFedora::File" do
      before do
        class FooHistory < ActiveFedora::Base
           directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles"), class_name:'ActiveFedora::File'
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no files" do
        let(:o) { FooHistory.new }
        subject { o.files }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end

        describe "#to_a" do
          subject { reloaded.files }
          it "has the content" do
            expect(subject.to_a).to eq [file]
          end
        end

        describe "#append" do
          let(:file2) { o.files.build }
          it "has two files" do
            expect(o.files).to eq [file, file2]
          end

          context "and then saved/reloaded" do
            before do
              file2.content = "Derp"
              o.save!
            end
            it "has two files" do
              expect(reloaded.files).to eq [file, file2]
            end
          end
        end
      end

      context "when the object is new" do
        let(:o) { FooHistory.new }
        let(:file) { o.files.build }

        it "fails" do
          # This is the expected behavior right now. In the future make the uri get assigned by autosave.
          expect { o.files.build }.to raise_error "Can't get uri. Owner isn't saved"
        end
      end
    end

    context "when contained elements are instances of a subclass of ActiveFedora::File" do
      before do
        class SubFile < ActiveFedora::File; end
        class FooHistory < ActiveFedora::Base
           directly_contains :files, has_member_relation: ::RDF::URI.new("http://example.com/hasFiles"), class_name: 'SubFile'
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
        Object.send(:remove_const, :SubFile)
      end

      let(:o) { FooHistory.create }
      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      describe "#build" do
        subject { file }
        it { is_expected.to be_kind_of SubFile }
      end

      context "when the object exists" do
        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end
      end
    end

    context "when using is_member_of_relation" do
      before do
        class FooHistory < ActiveFedora::Base
           directly_contains :files, is_member_of_relation: ::RDF::URI.new("http://example.com/isWithin")
        end
      end
      after do
        Object.send(:remove_const, :FooHistory)
      end

      let(:file) { o.files.build }
      let(:reloaded) { FooHistory.find(o.id) }

      context "with no files" do
        let(:o) { FooHistory.new }
        subject { o.files }

        it { is_expected.to be_empty }
        it { is_expected.to eq [] }
      end

      context "when the object exists" do
        let(:o) { FooHistory.create }

        before do
          file.content = "HMMM"
          o.save
        end

        describe "#first" do
          subject { reloaded.files.first }
          it "has the content" do
            expect(subject.content).to eq 'HMMM'
          end
        end
      end
    end
  end

  describe "#include?" do

    before do
      class FooHistory < ActiveFedora::Base
        directly_contains :files, has_member_relation: ::RDF::URI.new('http://example.com/hasFiles')
      end
    end

    after do
      Object.send(:remove_const, :FooHistory)
    end

    let(:foo) { FooHistory.create }

    let!(:file1) { foo.files.build }

    before do
      file1.content = 'hmm'
      foo.save
    end

    context "when it is not loaded" do
      context "and it contains the file" do
        subject { foo.reload.files.include? file1 }
        it { is_expected.to be true }
      end

      context "and it doesn't contain the file" do
        let!(:file2) { ActiveFedora::File.new.tap { |f| f.content= 'hmm'; f.save } }
        subject { foo.reload.files.include? file2 }
        it { is_expected.to be false }
      end
    end

    context "when it is loaded" do
      before { foo.files.to_a } # initial load of the association

      context "and it contains the file" do
        subject { foo.files.include? file1 }
        it { is_expected.to be true }
      end

      context "and it doesn't contain the file" do
        let!(:file2) { ActiveFedora::File.new.tap { |f| f.content= 'hmm'; f.save } }
        subject { foo.files.include? file2 }
        it { is_expected.to be false }
      end
    end
  end

end
