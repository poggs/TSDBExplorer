#
#  This file is part of TSDBExplorer.
#
#  TSDBExplorer is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  TSDBExplorer is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
#  Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with TSDBExplorer.  If not, see <http://www.gnu.org/licenses/>.
#
#  $Id$
#

require 'spec_helper'

describe "lib/tsdbexplorer.rb" do

  it "should validate a correctly formatted train identity" do
  
    TSDBExplorer.validate_train_identity("1A99").should be_true
    TSDBExplorer.validate_train_identity("2Z00").should be_true
    TSDBExplorer.validate_train_identity("3C01").should be_true
    TSDBExplorer.validate_train_identity("9O10").should be_true

  end

  it "should reject an incorrectly formed train identity" do

    TSDBExplorer.validate_train_identity(nil).should be_false
    TSDBExplorer.validate_train_identity("").should be_false
    TSDBExplorer.validate_train_identity("0000").should be_false
    TSDBExplorer.validate_train_identity("AAAA").should be_false
    TSDBExplorer.validate_train_identity("foobarbaz").should be_false

  end

  it "should validate a correctly formatted train UID" do

    TSDBExplorer.validate_train_uid("A00000").should be_true
    TSDBExplorer.validate_train_uid("C11111").should be_true
    TSDBExplorer.validate_train_uid("Z99999").should be_true

  end

  it "should reject an incorrectly formatted train UID" do

    TSDBExplorer.validate_train_uid(nil).should be_false
    TSDBExplorer.validate_train_uid("").should be_false
    TSDBExplorer.validate_train_uid("000000").should be_false
    TSDBExplorer.validate_train_uid("AAAAAA").should be_false
    TSDBExplorer.validate_train_uid("foobarbaz").should be_false

  end

  it "should convert a date in YYMMDD format to YYYY-MM-DD" do

    TSDBExplorer.ddmmyy_to_date("010160").should eql("1960-01-01")
    TSDBExplorer.ddmmyy_to_date("311299").should eql("1999-12-31")
    TSDBExplorer.ddmmyy_to_date("010100").should eql("2000-01-01")
    TSDBExplorer.ddmmyy_to_date("311259").should eql("2059-12-31")

  end

  it "should convert a date in YYMMDD format to YYYY-MM-DD" do

    TSDBExplorer.yymmdd_to_date("600101").should eql("1960-01-01")
    TSDBExplorer.yymmdd_to_date("991231").should eql("1999-12-31")
    TSDBExplorer.yymmdd_to_date("000101").should eql("2000-01-01")
    TSDBExplorer.yymmdd_to_date("591231").should eql("2059-12-31")

  end

  it "should be able to split a line in to fields based on an array" do

    sample_data = "AABBCCCDDDDEEEEE      FFFFFFF8888888899  99  9"
    sample_data_format = [ [ :one, 2 ], [ :two, 2 ], [ :three, 3], [ :four, 4 ], [ :five, 5 ], [ :six, 6], [ :seven, 7 ], [ :eight, 8], [ :nine, 9] ]

    returned_data = TSDBExplorer.cif_parse_line(sample_data, sample_data_format)

    expected_data = { :one => "AA", :two => "BB", :three => "CCC", :four => "DDDD", :five => "EEEEE", :six => "      ", :seven => "FFFFFFF", :eight => "88888888", :nine => "99  99  9" }
    
    returned_data.should eql(expected_data)

  end

  it "should validate a correctly formatted File Mainframe Identity in a CIF HD record" do

    file_mainframe_identity_1 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.UDFXXXX.PD700101")
    file_mainframe_identity_1.should have_key(:username)
    file_mainframe_identity_1[:username].should eql("DFXXXX")
    file_mainframe_identity_1.should have_key(:extract_date)
    file_mainframe_identity_1[:extract_date].should eql("700101")
    file_mainframe_identity_1.should_not have_key(:error)

    file_mainframe_identity_2 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.UCFXXXX.PD700101")
    file_mainframe_identity_2.should have_key(:username)
    file_mainframe_identity_2[:username].should eql("CFXXXX")
    file_mainframe_identity_2.should have_key(:extract_date)
    file_mainframe_identity_2[:extract_date].should eql("700101")
    file_mainframe_identity_2.should_not have_key(:error)

  end

  it "should reject an incorrectly formatted File Mainframe Identity in a CIF HD record" do

    file_mainframe_identity_1 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.Ufoo.PD700101")
    file_mainframe_identity_1.should have_key(:error)
    file_mainframe_identity_1[:error].should_not be_nil

    file_mainframe_identity_2 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.U.PD700101")
    file_mainframe_identity_2.should have_key(:error)
    file_mainframe_identity_2[:error].should_not be_nil

    file_mainframe_identity_3 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.UZZXXXX.PD700101")
    file_mainframe_identity_3.should have_key(:error)
    file_mainframe_identity_3[:error].should_not be_nil

    file_mainframe_identity_4 = TSDBExplorer.cif_parse_file_mainframe_identity("TPS.UDFZZZZ.PDfoobar")
    file_mainframe_identity_4.should have_key(:error)
    file_mainframe_identity_4[:error].should_not be_nil

  end

  it "should reject an empty CIF file" do
    lambda { TSDBExplorer::CIF::process_cif_file('test/fixtures/cif/blank_file.cif') }.should raise_error
  end

  it "should reject a CIF file with an unknown record" do
    result = TSDBExplorer::CIF::process_cif_file('test/fixtures/cif/unknown_record_type.cif')
    result.should have_key(:error)
  end

  it "should permit a CIF file with only an HD and ZZ record" do
    expected_data = {:tiploc=>{:insert=>0, :delete=>0, :amend=>0}}
    TSDBExplorer::CIF::process_cif_file('test/fixtures/cif/header_and_trailer.cif').should eql(expected_data)
  end

  it "should process TI records from a CIF file" do
    Tiploc.all.count.should eql(0)
    expected_data = {:tiploc=>{:insert=>1, :delete=>0, :amend=>0}}
    TSDBExplorer::CIF::process_cif_file('test/fixtures/cif/record_ti.cif').should eql(expected_data)
    Tiploc.all.count.should eql(1)
  end

  it "should process TA records from a CIF file"

  it "should process TD records from a CIF file"

end
