require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::ManyToMany do

  let(:person) do
    Person.new
  end

  let(:preference) do
    Preference.new
  end

  let(:target) do
    Mongoid::Relations::Targets::Enumerable.new([ preference ])
  end

  let(:metadata) do
    Person.relations["preferences"]
  end

  describe "#bind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is bindable" do

      let(:preference_two) do
        Preference.new
      end

      before do
        binding.bind_one(preference_two)
      end

      it "sets the inverse foreign key" do
        preference_two.person_ids.should == [ person.id ]
      end

      it "passes the binding options through to the inverse" do
        person.expects(:save).never
      end

      it "syncs the base" do
        person.should be_synced("preference_ids")
      end

      it "syncs the inverse" do
        preference_two.should be_synced("person_ids")
      end
    end

    context "when ensuring minimal saves" do

      let(:preference_two) do
        Preference.new.tap do |pref|
          pref.new_record = false
        end
      end

      it "does not save the parent on bind" do
        person.expects(:save).never
        binding.bind_one(preference_two)
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        person.preferences.expects(:<<).never
        binding.bind_one(preference)
      end
    end
  end

  describe "#unbind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind_one(target.first)
        person.expects(:delete).never
        preference.expects(:delete).never
        binding.unbind_one(target.first)
      end

      it "removes the inverse relation" do
        preference.people.should be_empty
      end

      it "removed the foreign keys" do
        preference.person_ids.should be_empty
      end

      it "syncs the base" do
        person.should be_synced("preference_ids")
      end

      it "syncs the inverse" do
        preference.should be_synced("person_ids")
      end
    end

    context "when preventing multiple db hits" do

      before do
        binding.bind_one(target.first)
      end

      it "never performs a persistance operation" do
        person.expects(:delete).never
        person.expects(:save).never
        preference.expects(:delete).never
        preference.expects(:save).never
        binding.unbind_one(target.first)
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        person.expects(:preferences=).never
        binding.unbind_one(target.first)
      end
    end
  end
end
