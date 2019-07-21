my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ4/".$proj_name."/";
my $proj_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/historical versions/r".$version_number."_".$date."/";
my $log_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/log.txt";
my $git_cmd = "git --git-dir=\"".$proj_path.".git\" --work-tree=\"".$proj_path."\"";

my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my %dev_email_rec;
my @crtp_record = ();
my @func_record = ();

## process log file to get the commiting information of developers
open(my $fh_log, $log_path) or die "Could not open the log file".$proj_name."\n";
my $dev_name = "";
while(my $line_text = <$fh_log>){
	my @match_words = ();
	if(@match_words = ($line_text =~ /^Author:\s(.+)\s<(\S+)>/)){
		$dev_name = $match_words[0];
		my $email = $match_words[1];
		print $dev_name.":".$email."\n";
		next if $dev_email_rec{$dev_name};
		$dev_email_rec{$dev_name} = $email;
	}
}
close($fh_log);

####################
## process CRTP   ##
####################
my @class_temp_ids = ();
foreach my $class_temp ($db->ents("C Class Template")){
	my $id = $class_temp->id();
	push(@class_temp_ids, $id);
}
foreach my $class ($db->ents("C Class")){
	# the class cannot by a class template
	my $id = $class->id();
	next if (grep { $_ eq $id } @class_temp_ids);
	my $class_longname = $class->longname();
	my $class_name = $class->name();
	my $is_user_def_class = 1;
	my $uses = 0;
	my @edit_info = ("", "");
	my $class_def_file = "";
	my $class_def_line = -1;
	# to determine whether it is a library class
	my @metriclist = ("AltCountLineCode");
	my @value = $class->metric(@metriclist);
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party class
	elsif($class_longname =~ /($third_party_lib_prefix)/){
		$is_user_def_class = 0;
	}
	next unless $is_user_def_class;
	# check whether the class implements CRTP
	my $is_crtp = 0;
	foreach my $ref ($class->refs("C base")){
		my $base_class = $ref->ent();
		my $base_class_id = $base_class->id();
		# if the base class is a template, check whether it is an implementation of CRTP
		if(grep { $_ eq $base_class_id } @class_temp_ids){
			my $lex = $ref->lexeme();
			next unless $lex;
			$is_crtp = checkCRTP($lex,$class_name);
			last if $is_crtp;
		}
	}
	next unless $is_crtp;
	# get the definition info of this class
	foreach my $ref ($class->ref("C Definein")){
		# if the class is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined class
		my $ref_file = $ref->file->longname();
		$is_user_def_class = 0 if $ref_file =~ /($third_party_lib_path)/;
		# only user-defines classes in C++ files are processed
		last unless $is_user_def_class;
		$class_def_file = $ref->file->longname();
		$class_def_line = $ref->line();
		@edit_info = getEditInfo($class_def_file, $class_def_line);
		last;
	}
	next unless $is_user_def_class;
	# get the use info of this class
	foreach my $ref ($class->refs()){
		my $ref_file = $ref->file()->longname();
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# process different kinds of refs
			if($ref_name eq "C Typedby" or $ref_name eq "C Useby" or $ref_name eq "C Inactive Useby" 
			or $ref_name eq "C Cast Useby" or $ref_name eq "C Nameby" or $ref_name eq "C Friendby"
			or $ref_name eq "C Derive"){
				$uses ++;
			}
		}
	}
	# record the use of CRTP: register the class name, uses, developer, email, edit time, definition file, line number
	my @local_record = ();
	push(@local_record, $class_longname);
	push(@local_record, $uses);
	my $dev_name = $edit_info[0];
	my $dev_email = "";
	if(exists($dev_email_rec{$dev_name})){
		$dev_email = $dev_email_rec{$dev_name};
	}
	my $edit_time = $edit_info[1];
	push(@local_record, $dev_name);
	push(@local_record, $dev_email);
	push(@local_record, $edit_time);
	my $skipCharNum = length($proj_path);
	my $filePath = substr($class_def_file, $skipCharNum);
	push(@local_record, $filePath);
	push(@local_record, $class_def_line);
	push(@crtp_record, [@local_record]);
	print("class_name=", $class_longname,",uses=",$uses,"\n");
	print("	dev_name=",  $dev_name, "dev_email=", $dev_email,", edit_time=", $edit_time,"\n");
	print(" ",$class_def_file, ", line=", $class_def_line,"\n");
}


#################################
## process virtual functions   ##
#################################
print $proj_name."-".$version_number."_".$date."==========process functions\n";
foreach my $func ($db->ents("C Member Function Virtual")){
	# determine whether the function is a member of class template
	my $parent_ent = $func->parent();
	if($parent_ent){
		my $id = $parent_ent->id();
		next if (grep { $_ eq $id } @class_temp_ids);
	} else{
		next;
	}
	# process the function
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_func = 1;
	my $is_destructor = 0;
	my @edit_info = ("", "");
	my $call_count = 0;
	my @instantiated_argument_types = ();
	# to determine whether it is a library function
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party function
	elsif($func_name =~ /($third_party_lib_prefix)/){
		$is_user_def_func = 0;
	}
	# to determine whether it is a destructor
	elsif($func_name =~ /~/){
		$is_destructor = 1;
	}
	next unless $is_user_def_func;
	next if $is_destructor;
	my $defined_in_cpp = 1;
	my $func_def_file = "";
	my $func_def_line = -1;
	# get the definition info of this function
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
		# if the function is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined function
		if($ref_name eq "C Definein"){
			my $ref_file = $ref->file->longname();
			$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
			$is_user_def_func = 0 if $ref_file =~ /($third_party_lib_path)/;
			# only user-defines functions in C++ files are processed
			last unless $is_user_def_func;
			last unless $defined_in_cpp;
			$func_def_file = $ref->file->longname();
			$func_def_line = $ref->line();
			@edit_info = getEditInfo($func_def_file, $func_def_line);
			last;
		}
	}
	next if ($func_def_file eq "");
	# to get the use info of this function
	foreach my $ref ($func->refs()){
		my $ref_file = $ref->file()->longname();
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# if the function is called
			if($ref_name eq "C Callby"){
				$call_count ++;
			}
		}
	}
	# register the function name, call count, developer, email, edit time, definition file, line number
	my @local_record = ();
	push(@local_record, $func_name);
	push(@local_record, $call_count);
	my $dev_name = $edit_info[0];
	my $dev_email = "";
	if(exists($dev_email_rec{$dev_name})){
		$dev_email = $dev_email_rec{$dev_name};
	}
	my $edit_time = $edit_info[1];
	push(@local_record, $dev_name);
	push(@local_record, $dev_email);
	push(@local_record, $edit_time);
	my $skipCharNum = length($proj_path);
	my $filePath = substr($func_def_file, $skipCharNum);
	push(@local_record, $filePath);
	push(@local_record, $func_def_line);
	push(@func_record, [@local_record]);
	print("func_name=", $func_name," call_count=", $call_count,"\n");
	print("	dev_name=",  $dev_name, "dev_email=", $dev_email,", edit_time=", $edit_time,"\n");
	print(" ",$func_def_file, ", line=", $func_def_line,"\n");
}

# ===============================================================================================================================================
# subprogram to get editing information
sub getEditInfo{
	my $file_name = $_[0];
	my $line_num = $_[1];
	# get git blame info
	# print "filename: $file_name\n";
	my $blame_cmd = "$git_cmd blame -w -L $line_num,+1 \"$file_name\"";
	# print "blame_cmd: $blame_cmd\n";
	my $blame_info = `$blame_cmd`;
	# print $blame_info;
	# get developer name and editing date from git blame info
	$blame_info =~ /\(((\s|\S)+)\s(\d+)-(\d+)-(\d+)/;
	my ($dev_name, $space, $year, $month, $day) = ($1, $2, $3, $4, $5);
	# print $dev_name." ".$space." ".$year." ".$month." ".$day."\n";
	my $date = $year.$month.$day;
	my @ret_rec = ($dev_name, $date);
	return @ret_rec;
}

sub checkCRTP{
	my $lex = $_[0];
	my $class_name = $_[1];
	# to find the type argument which instantiates class template
	while($lex->text() ne "<"){
		$lex = $lex->next();
		last unless $lex;
	}
	my $angle_brackets = 0;
	if($lex && $lex->text() eq "<"){
		$angle_brackets ++;
		while($angle_brackets > 0){
			$lex = $lex->next();
			last unless $lex;
			if($lex->text() eq $class_name){
				return 1;
			} elsif($lex->text() eq "<"){
				$angle_brackets ++;
			} elsif($lex->text() eq ">"){
				$angle_brackets --;
			} elsif($lex->text() eq ">>"){
				$angle_brackets -= 2;
			} 
		}
	}
	return 0;
}
# ===============================================================================================================================================
# write info into excel
my $output_path = $common_output_path.$proj_name."-".$version_number."_RQ4.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "class implementing CRTP, uses, developer, email, edit time, definition file path, line\n");
foreach my $iter (@crtp_record){
	my @crtp_rec = @{$iter};
	syswrite("metricfile", "$crtp_rec[0], //$crtp_rec[1], //$crtp_rec[2], //$crtp_rec[3], //$crtp_rec[4], //$crtp_rec[5], //$crtp_rec[6]\n");
}
syswrite("metricfile", "\n");
syswrite("metricfile", "virtual function, calls, developer, email, edit time, definition file path, line\n");
foreach my $iter (@func_record){
	my @func_rec = @{$iter};
	syswrite("metricfile", "$func_rec[0], //$func_rec[1], //$func_rec[2], //$func_rec[3], //$func_rec[4], //$func_rec[5], //$func_rec[6]\n");
}
close("metricfile");