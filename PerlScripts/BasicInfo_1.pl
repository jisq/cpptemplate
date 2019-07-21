my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/BasicInfo_1/";
my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my %revision_sloc_rec;
my %revision_devs_rec;
my %revision_age_rec;
my @revision_info_rec = ();

# get info from the historical revision record file
my @revision_numbers;
my $historical_revision_rec_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/historical versions/".$proj_name.".txt";
open(my $fh, '<:encoding(UTF-8)', $historical_revision_rec_path) or die "Could not open file '$historical_revision_rec_path' $!";
while (my $line_text = <$fh>) {
	my @sub_strs = split(" ",$line_text);
	next if (scalar @sub_strs) != 2;
	my $revision_number = $sub_strs[0];
	push(@revision_numbers, $revision_number);
}
close($fh);

# record info of each revision
my $log_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/log.txt";
getRevisionInfo($log_path);

# get information of each historical revision
foreach my $revision_num (@revision_numbers){
	print($proj_name."-".$revision_num."\n");
	# get SLOC
	my $udb_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Understand Databases/".$proj_name."/".$proj_name."-".$revision_num.".udb";
	my $sloc = getLoc($udb_path);
	$revision_sloc_rec{$revision_num} = $sloc;
	# get number of developers and project age
	my @devs_age = getDevsAndAge($revision_num);
	$revision_devs_rec{$revision_num} = $devs_age[0];
	$revision_age_rec{$revision_num} = $devs_age[1];
}

#================================================================================
# subprogram to get SLOC
sub getLoc{
	my $udb_path = $_[0];
	my $db = Understand::open($udb_path);
	my $sloc = 0;	
	# Traverse all C++ files
	foreach my $file ($db->ents("C Code File")){
		my $fname = $file->longname();
		if($fname =~ /\.(C|cc|cpp|cxx)$/ and $fname !~ /($third_party_lib_path)/){
			my @metriclist = ("AltCountLineCode");
			my @value = $file->metric(@metriclist);
			$sloc += $value[0];
		}
	}
	foreach my $file ($db->ents("C Header File")){
		my $fname = $file->longname();
		my $is_valid_head_file = 1;
		foreach my $file_unknown ($db->ents("C Unknown Header File")){
			my $fname_unknown = $file_unknown->longname();
			if($fname eq $fname_unknown){
				$is_valid_head_file = 0;
				last;
			}
		}
		if($is_valid_head_file == 0){
			next;
		}
		foreach my $file_unresolved ($db->ents("C Unresolved Header File")){
			my $fname_unresolved = $file_unresolved->longname();
			if($fname eq $fname_unresolved){
				$is_valid_head_file = 0;
				last;
			}
		}
		if($is_valid_head_file == 0){
			next;
		}
		if($fname =~ /\.(H|h|hh|hpp|hxx)$/ and $fname !~ /($third_party_lib_path)/){
			my @metriclist = ("AltCountLineCode");
			my @value = $file->metric(@metriclist);
			$sloc += $value[0];
		}
	}
	$db->close();
	return $sloc;
}

# subprogram to get revision info: hash code, developer name, committing year
sub getRevisionInfo{
	my $log_path = $_[0];
	# read the log file
	open(my $fh, '<:encoding(UTF-8)', $log_path) or die "Could not open file '$log_path' $!";
	my $revision_num = -1;
	my $author = "";
	my $year = -1;
	my $flag_new_revision = 0;
	while (my $line_text = <$fh>) {
		my @match_words = ();
		# read new revision number
		if(@match_words=($line_text =~ /^commit(\s+)(\S+)/)){
			$revision_num = $match_words[1];
			$flag_new_revision = 1;
		}
		next unless $flag_new_revision;
		# read committer's info
		if(@match_words = ($line_text =~ /^Author:\s(.+)\s<(\S+)>/)){
			$author = $match_words[1];
		}
		# read the year of commitment
		if(@match_words = ($line_text =~ /^Date:(\s+)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)/)){
			$flag_new_revision = 0;
			my $year = $match_words[9];
			# record information of the new commitment
			my @local_rec = ($revision_num,$author,$year);
			push(@revision_info_rec, [@local_rec]);
		}
	}
	close($fh);
}

# subprogram to get number of developers and project age
sub getDevsAndAge{
	my $revision_num = $_[0];
	my $year_of_revision = -1;
	my $year_of_establishment = -1;
	my @dev_emails = ();
	# get the info of this revision
	my $flag_revision_found = 0;
	foreach my $item (@revision_info_rec){
		my @rec_iter = @{$item};
		my $rec_iter_revision_num = $rec_iter[0];
		my $rec_iter_dev_email = $rec_iter[1];
		my $rec_iter_year = $rec_iter[2];
		# to find the record of a revision
		if(!$flag_revision_found and ($rec_iter_revision_num eq $revision_num)){
			print("found:".$revision_num."\n");
			$flag_revision_found = 1;
			$year_of_revision = $year_of_establishment = $rec_iter_year;
			push(@dev_emails, $rec_iter_dev_email);
		} elsif($flag_revision_found){
			if($year_of_establishment > $rec_iter_year){
				$year_of_establishment = $rec_iter_year;
			}
			next if (grep { $_ eq $rec_iter_dev_email } @dev_emails);
			push(@dev_emails, $rec_iter_dev_email);
		}
	}
	my $dev_num = scalar(@dev_emails);
	my $age = 1 + $year_of_revision - $year_of_establishment;
	my @ret_val = ($dev_num, $age);
	return @ret_val;
}

# write information into excel
# ===============================================================================================================================================
my $output_path = $common_output_path.$proj_name."_BasicInfo_1.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "revision no., SLOC, developers, age\n");
foreach my $revision_num (@revision_numbers){
	my $sloc = $revision_sloc_rec{$revision_num};
	my $devs = $revision_devs_rec{$revision_num};
	my $age = $revision_age_rec{$revision_num};
	syswrite("metricfile", "$revision_num, $sloc, $devs, $age\n");
}
close("metricfile");
