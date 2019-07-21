use Understand;
use strict;
use warnings;

my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my $common_script_dir = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/PerlScripts/TemporalScripts/";
my $result_dir = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/";
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/";
my @proj_names = ();
my %proj_sloc_rec;
my %proj_devs_rec;
my %proj_age_rec;

# get info from RecentProjectInfo.csv file
my $input_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/ProjectInfo/ProjectInfo.csv";
open(my $fh, '<:encoding(UTF-8)', $input_path) or die "Could not open file '$input_path' $!";
while (my $line_text = <$fh>) {
	# print $line_text;
	my @sub_strs = split(",",$line_text);
	next if (scalar @sub_strs) != 3;
	my $proj_name = $sub_strs[0];
	push(@proj_names, $proj_name);
}
close($fh);

if(!(-e $result_dir)){
	system("mkdir -p \"$result_dir\"") == 0 or die "mkdir result dir failed";
}

# process all projects
my $proj_count = 0;
foreach my $proj_name (@proj_names) {
	$proj_count ++;
	print $proj_count.":".$proj_name."\n";
	# process each project to get the info, including sloc, number of devs, and project age
	getProjInfo($proj_name);
}

##========================================================
# subprogram to get project info
sub getProjInfo{
	my $proj_name = $_[0];
	# get SLOC
	my $udb_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Understand Databases/".$proj_name."/".$proj_name.".udb";
	$proj_sloc_rec{$proj_name} = getLoc($udb_path);
	# get number of developers and project age
	getDevsAndAge($proj_name);
}

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
sub getDevsAndAge{
	my $proj_name = $_[0];
	# read the log file
	my $log_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/log.txt";
	open(my $fh, '<:encoding(UTF-8)', $log_path) or die "Could not open file '$log_path' $!";
	my @author = ();
	my $end_year = -1;
	my $begin_year = -1;
	while (my $line_text = <$fh>) {
		my @match_words = ();
		# read committer's info
		if(@match_words = ($line_text =~ /^Author:\s(.+)\s<(\S+)>/)){
			my $cur_author = $match_words[1];
			if(!(grep { $_ eq $cur_author } @author)){
				push(@author,$cur_author);
			}
		}
		# read the year of commitment
		if(@match_words = ($line_text =~ /^Date:(\s+)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)/)){
			my $year = $match_words[9];
			if($end_year == -1){
				$end_year = $year;
			}
			if($begin_year == -1 || $begin_year > $year){
				$begin_year = $year;
			}
		}
	}
	close($fh);
	my $num_of_authors = scalar(@author);
	my $age = 1+$end_year-$begin_year;
	$proj_devs_rec{$proj_name} = $num_of_authors;
	$proj_age_rec{$proj_name} = $age;
}

# write information into excel
# ===============================================================================================================================================
my $output_path = $common_output_path."BasicInfo_0.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "project name, SLOC, developers, age\n");
foreach my $proj_name (@proj_names){
	my $sloc = $proj_sloc_rec{$proj_name};
	my $devs = $proj_devs_rec{$proj_name};
	my $age = $proj_age_rec{$proj_name};
	syswrite("metricfile", "$proj_name, $sloc, $devs, $age\n");
}
close("metricfile");
