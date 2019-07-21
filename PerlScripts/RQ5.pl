
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ5/";
my $proj_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/latest version/";
my $log_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/log.txt";
my $git_cmd = "git --git-dir=\"".$proj_path.".git\" --work-tree=\"".$proj_path."\"";

my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

## Info of developers
my %dev_email_rec;
my %dev_commit_rec;
my %dev_start_year_rec;
my %dev_end_year_rec;
## library template use info for developers
my %developer_lib_func_temp_use;
my %developer_lib_class_temp_use;
## user-defined template use info for developers
my %developer_user_def_func_temp_use;
my %developer_user_def_class_temp_use;

## update info of template use
sub apdateDevInfo{
	my ($ref, $is_user_def_temp, $func_or_class) = @_;
	my $file_name = $ref->file()->longname();
        my $line_num = $ref->line();
        if($file_name =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $file_name !~ /($third_party_lib_path)/){
		# to get blame info
		print "filename: $file_name\n";
		# print $git_cmd." blame -w -L ".$line_num.",+1 \"".$file_name."\"\n";
		my $blame_cmd = "$git_cmd blame -w -L $line_num,+1 \"$file_name\"";
		print "blame_cmd: $blame_cmd\n";
		my $blame_info = `$blame_cmd`;
		print $blame_info;
		# to get the developer's name according to blame info
		$blame_info =~ /\(((\s|\S)+)\s(\d+)-(\d+)-(\d+)/;
		my ($dev_name, $space, $year, $month, $day) = ($1, $2, $3, $4, $5);
		print $dev_name." ".$space." ".$year." ".$month." ".$day."\n";
		# register developer's info into hash table
		if($is_user_def_temp){
			if($func_or_class eq "function"){
				if (exists($developer_user_def_func_temp_use{$dev_name})){
					$developer_user_def_func_temp_use{$dev_name} ++;
				} else{
					$developer_user_def_func_temp_use{$dev_name} = 1;
				}
			}
			elsif($func_or_class eq "class"){
				if (exists($developer_user_def_class_temp_use{$dev_name})){
					$developer_user_def_class_temp_use{$dev_name} ++;
				} else{
					$developer_user_def_class_temp_use{$dev_name} = 1;
				}
			}
		} else{
			if($func_or_class eq "function"){
				if (exists($developer_lib_func_temp_use{$dev_name})){
					$developer_lib_func_temp_use{$dev_name} ++;
				} else{
					$developer_lib_func_temp_use{$dev_name} = 1;
				}
			}
			elsif($func_or_class eq "class"){
				if (exists($developer_lib_class_temp_use{$dev_name})){
					$developer_lib_class_temp_use{$dev_name} ++;
				} else{
					$developer_lib_class_temp_use{$dev_name} = 1;
				}
			}
		}
	}
}

## process class templates
processClassTemplates("C Class Template");
processClassTemplates("C Struct Template");
sub processClassTemplates{
	foreach my $class ($db->ents($_[0])){
		my $class_name = $class->longname();
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		my $is_user_def_template = 1;
		# to determine whether it is a library template
		if(not defined($value[0])){
			$is_user_def_template = 0;
			if($class_name !~ /$namespace_mark/){
				next;
			}
			if($class_name !~ /$std_lib_prefix/ and $class_name !~ /($third_party_lib_prefix)/){
				next;
			}
		}
		# to determine whether it is a 3rd-party library template
		elsif($class_name =~ /($third_party_lib_prefix)/){
			$is_user_def_template = 0;
		}
		my $defined_in_cpp = 1;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# process class template definition
			if($ref_name eq "C Definein"){
				my $ref_file = $ref->file->longname();
				$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
				last;
			}
		}
		next unless $defined_in_cpp;
		# traverse the refs in valid C++ files
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			if($ref_name eq "C Typedby" or $ref_name eq "C Useby" or $ref_name eq "C Inactive Useby" 
			or $ref_name eq "C Cast Useby" or $ref_name eq "C Nameby" or $ref_name eq "C Friendby"){
				apdateDevInfo($ref, $is_user_def_template, "class");
			}
		}
	}
}

## process function templates
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_template = 1;
	# to determine whether it is a library template
	if(not defined($value[0])){
		$is_user_def_template = 0;
		if($func_name !~ /$namespace_mark/){
			next;
		}
		if($func_name !~ /$std_lib_prefix/ and $func_name !~ /($third_party_lib_prefix)/){
			next;
		}
	}
	# to determine whether it is a 3rd-party library template
	elsif($func_name =~ /($third_party_lib_prefix)/){
		$is_user_def_template = 0;
	}
	my $defined_in_cpp = 1;
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
		# if the function template is defined in 3rd-party C++ files
		if($ref_name eq "C Definein"){
			my $ref_file = $ref->file->longname();
			$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
			$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
			last;
		}
	}
	next unless $defined_in_cpp;
	# traverse the refs of this function template
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
                # if the function template is called
                if($ref_name eq "C Callby"){
                	apdateDevInfo($ref, $is_user_def_template, "function");
                }
	}
}

## process log file to get the commiting information of developers
open(my $fh_log, $log_path) or die "Could not open the log file".$proj_name."\n";
my $dev_name = "";
while(my $line_text = <$fh_log>){
	my @match_words = ();
	if(@match_words = ($line_text =~ /^Author:\s(.+)\s<(\S+)>/)){
		$dev_name = $match_words[0];
		my $email = $match_words[1];
		print $dev_name.":".$email."\n";
		if(exists($dev_commit_rec{$dev_name})){
			$dev_commit_rec{$dev_name} ++;
		} else{
			$dev_commit_rec{$dev_name} = 1;
			$dev_email_rec{$dev_name} = $email;
		}
	}
	# get the start year and the end year when developer is involved in the community 
	if(($dev_name ne "") && (@match_words = ($line_text =~ /^Date:(\s+)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)(\s)(\S+)/))){
		my $year = $match_words[9];
		if((not exists($dev_start_year_rec{$dev_name})) || ($dev_start_year_rec{$dev_name} > $year)){
			$dev_start_year_rec{$dev_name} = $year;
		}
		if((not exists($dev_end_year_rec{$dev_name})) || ($dev_end_year_rec{$dev_name} < $year)){
			$dev_end_year_rec{$dev_name} = $year;
		}
	}
}
close($fh_log);

# write info into excel
# ===============================================================================================================================================
my $output_path = $common_output_path.$proj_name."_RQ5.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
print "=========================================\n";
syswrite("metricfile", "developer, email, commits, start year, end year, #lib class temp uses, #lib func temp uses, #user-defined class temp uses, #user-defined func temp uses\n");
foreach my $key (keys %dev_commit_rec) {
	my $email = $dev_email_rec{$key};
	my $commit_count = $dev_commit_rec{$key};
	my $start_year = $dev_start_year_rec{$key};
	my $end_year = $dev_end_year_rec{$key};
	my $lib_class_use_count = 0;
	$lib_class_use_count = $developer_lib_class_temp_use{$key} if exists($developer_lib_class_temp_use{$key});
	my $lib_func_use_count = 0;
	$lib_func_use_count = $developer_lib_func_temp_use{$key} if exists($developer_lib_func_temp_use{$key});
	my $user_def_class_use_count = 0;
	$user_def_class_use_count = $developer_user_def_class_temp_use{$key} if exists($developer_user_def_class_temp_use{$key});
	my $user_def_func_use_count = 0;
	$user_def_func_use_count = $developer_user_def_func_temp_use{$key} if exists($developer_user_def_func_temp_use{$key});
	syswrite("metricfile", "$key, //$email, //$commit_count, //$start_year, //$end_year, //$lib_class_use_count, //$lib_func_use_count, //$user_def_class_use_count, //$user_def_func_use_count\n");
}
close("metricfile");
