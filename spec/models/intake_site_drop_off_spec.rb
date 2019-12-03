require 'rails_helper'

describe IntakeSiteDropOff do
  let(:drop_off) { build :intake_site_drop_off }

  describe "whitespace from inputs" do
    it "doesn't save whitespace where it shouldn't" do
      drop_off.name = " Ben\t"
      drop_off.save

      expect(drop_off.name).to eq "Ben"
    end
  end

  describe "validations" do
    it "requires certain fields" do
      expect(drop_off).to be_valid

      invalid_drop_off = IntakeSiteDropOff.new()
      expect(invalid_drop_off).not_to be_valid
      expect(invalid_drop_off.errors).to include(:name)
      expect(invalid_drop_off.errors).to include(:intake_site)
      expect(invalid_drop_off.errors).to include(:signature_method)
      expect(invalid_drop_off.errors).to include(:document_bundle)
      expect(invalid_drop_off.errors.messages[:document_bundle]).to include "Please choose a file."
    end

    describe "#signature_method" do
      it "expects signature_method to be a valid choice" do
        drop_off.signature_method = "carrier pigeon"
        expect(drop_off).not_to be_valid
        expect(drop_off.errors.messages[:signature_method]).to include "Please select a pickup method."
      end
    end

    describe "#intake_site" do
      it "expects intake_site to be a valid choice" do
        drop_off.intake_site = "North Pole"
        expect(drop_off).not_to be_valid
        expect(drop_off.errors.messages[:intake_site]).to include "Please select an intake site."
      end
    end

    describe "#certification_level" do
      it "expects certification_level to be a valid choice" do
        drop_off.certification_level = "carrier pigeon"
        expect(drop_off).not_to be_valid
        expect(drop_off.errors.messages[:certification_level]).to include "Please select a certification level."
      end
    end

    describe "#email" do
      it "expects email to be a valid email" do
        drop_off.email = "gguava.example.com"
        expect(drop_off).not_to be_valid
        expect(drop_off.errors.messages[:email]).to include "Please enter a valid email."
      end
    end

    describe "#phone_number" do
      it "expects a valid phone number" do
        drop_off.phone_number = "12345678"
        expect(drop_off).not_to be_valid
        expect(drop_off.errors.messages[:phone_number]).to include "Please enter a valid phone number."
      end

      it "accepts common phone number formats" do
        drop_off.phone_number = "4158161286"
        expect(drop_off).to be_valid

        drop_off.phone_number = "(415)816-1286"
        expect(drop_off).to be_valid
      end
    end

    describe "#error_summary" do
      it "summarizes errors nicely" do
        expect(drop_off.error_summary).to eq nil

        drop_off.pickup_date_string = "02/20"
        drop_off.phone_number = "(555) 123-4567"
        expect(drop_off).to_not be_valid

        expect(drop_off.error_summary).to eq "Errors: Please enter a valid phone number. Please enter a valid date."
      end
    end
  end


  describe "#document_bundle" do
    it "can attach a document bundle" do
      drop_off.save
      drop_off.document_bundle.attach(io: File.open('spec/fixtures/attachments/document_bundle.pdf'), filename: 'document_bundle.pdf')

      expect(drop_off.document_bundle).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe "#phone_number" do
    it "normalizes phone numbers" do
      drop_off.phone_number = "4158161286"
      expect(drop_off.phone_number).to eq "14158161286"
      drop_off.phone_number = "(415) 816-1286"
      expect(drop_off.phone_number).to eq "14158161286"
      drop_off.phone_number = "+1(415) 816-1286"
      expect(drop_off.phone_number).to eq "14158161286"
      drop_off.phone_number = "+14158161286"
      expect(drop_off.phone_number).to eq "14158161286"
    end
  end

  describe "#formatted_phone_number" do
    it "returns a locally formatted phone number" do
      drop_off.phone_number = "4158161286"
      expect(drop_off.formatted_phone_number).to eq "(415) 816-1286"
    end
  end

  describe "#pickup_date_string" do
    it "is okay being empty" do
      expect(drop_off.pickup_date_string).to be_nil
    end

    it "formats the date appropriately" do
      drop_off.pickup_date = Date.new(2020, 2, 6)
      expect(drop_off.pickup_date_string).to eq "2/6/2020"
    end

    it "can parse a formatted date string" do
      drop_off.pickup_date_string = "02/6/2020"
      expect(drop_off).to be_valid
      expect(drop_off.pickup_date).to eq Date.new(2020, 2, 6)
    end

    it "adds validation errors for invalid dates" do
      drop_off.pickup_date_string = "02/2020"

      expect(drop_off).not_to be_valid
      expect(drop_off.errors.messages[:pickup_date]).to include "Please enter a valid date."
      expect(drop_off.pickup_date_string).to eq "02/2020"
    end
  end

  describe ".find_prior_drop_off" do
    let(:new_drop_off) do
      build(
        :intake_site_drop_off,
        name: "Heather Huckleberry",
        email: "heather@huckleberry.horse",
        phone_number: "4158161286",
      )
    end

    context "with a prior drop off that has the same email" do
      it "returns the previous drop off" do
        prior = create :intake_site_drop_off, name: "Frances Fig", email: "heather@huckleberry.horse"

        result = IntakeSiteDropOff.find_prior_drop_off(new_drop_off)

        expect(result).to eq prior
      end
    end

    context "with a prior drop off that has the same phone and name" do
      it "returns the previous drop off" do
        prior = create :intake_site_drop_off, name: "Heather Huckleberry", email: "", phone_number: "(415) 816-1286"

        result = IntakeSiteDropOff.find_prior_drop_off(new_drop_off)

        expect(result).to eq prior
      end
    end

    context "with drop offs that don't quite match" do
      it "returns nil" do
        create :intake_site_drop_off, name: "Heather Huckleberry", email: "", phone_number: "(415) 816-1234"
        create :intake_site_drop_off, name: "Heather Huckleberry", email: "", phone_number: "4158161283"
        create :intake_site_drop_off, name: "Heather Huckleberry", email: "", phone_number: ""

        result = IntakeSiteDropOff.find_prior_drop_off(new_drop_off)

        expect(result).to be_nil
      end
    end

    context "with blank email and phone" do
      let(:new_drop_off) { build :intake_site_drop_off, name: "Heather Huckleberry", email: "", phone_number: "" }

      context "with a prior name match" do
        it "returns the previous drop off" do
          prior = create :intake_site_drop_off, name: "Heather Huckleberry", email: "heather@huckleberry.horse", phone_number: "(415) 816-1286"

          result = IntakeSiteDropOff.find_prior_drop_off(new_drop_off)

          expect(result).to eq prior
        end
      end

      context "with prior blank emails and phones but no similar name" do
        it "returns nil" do
          create :intake_site_drop_off, name: "Heidi Honeydew", email: "", phone_number: ""
          create :intake_site_drop_off, name: "Frances Fig", email: "", phone_number: ""
          create :intake_site_drop_off, name: "Leon Lemon", email: "", phone_number: ""

          result = IntakeSiteDropOff.find_prior_drop_off(new_drop_off)

          expect(result).to be_nil
        end
      end
    end
  end
end