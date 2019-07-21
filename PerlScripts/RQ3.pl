my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ3/".$proj_name."/";
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
my @class_temp_record = ();
my @class_temp_ids = ();
my @class_hierarchy_record = ();
my @base_class_info;

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

## process class templates
print $proj_name."-".$version_number."============processing class templates\n";
process_class_templates("C Class Template");
process_class_templates("C Struct Template");

sub process_class_templates{
	foreach my $class ($db->ents($_[0])){
		my $class_name = $class->longname;
		my $is_user_def_template = 1;
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		my $instantiations = 0;
		my $multiple_overload_instantiations = 0;
		my $loc = 0;
		my @instantiated_argument_types = ();
		# to determine whether it is a library template
		if(not defined($value[0])){
			next;
		}
		# to determine whether it is a 3rd-party template
		elsif($class_name =~ /($third_party_lib_prefix)/){
			$is_user_def_template = 0;
		}
		my $defined_in_cpp = 1;
		my @edit_info = ("", "");
		my $temp_def_file = "";
		my $temp_def_line = -1;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# if the template is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined template
			if($ref_name eq "C Definein"){
				my $ref_file = $ref->file->longname();
				$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
				last unless $defined_in_cpp and $is_user_def_template;
				$temp_def_file = $ref->file->longname();
				$temp_def_line = $ref->line();
				print($temp_def_file,",",$temp_def_line,"\n");
				@edit_info = getEditInfo($temp_def_file, $temp_def_line);
				last;
			}
		}
		# only user-defined class templates in C++ files are processed
		next unless $is_user_def_template;
		next unless $defined_in_cpp;
		$loc = $value[0];
		# traverse the refs of this class template
		foreach my $ref ($class->refs()){
			my $ref_file = $ref->file()->longname();
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				my $ref_name = $ref->kind()->longname();
				# process different kinds of refs
				if($ref_name eq "C Typedby" or $ref_name eq "C Useby" or $ref_name eq "C Inactive Useby" 
				or $ref_name eq "C Cast Useby" or $ref_name eq "C Nameby" or $ref_name eq "C Friendby"){
					$instantiations ++;
					# to determine whether it is a new overload instantiation
					my @argument_types = ();
					my $line = $ref->line();
					my $column = $ref->column();
					if($ref_file and $line and $column){
						my $class_short_name = $class->simplename;
						@argument_types = getTempArgTexts($ref, $class_short_name);
					}
					# if no argument is found
					next if @argument_types == 0;
					# if there is any argument type not resolved, then jump over
					my $has_unresolved = 0;
					foreach my $arg_type (@argument_types){
						if($arg_type eq ""){
							$has_unresolved = 1;
							last;
						}
					}
					next if $has_unresolved;
					# if there are different argument types
					my $is_new = 1;
					foreach my $aref (@instantiated_argument_types){
						my @arg_types = @{$aref};
						next if @arg_types != @argument_types;
						my $is_same = 1;
						my $index = 0;
						foreach my $arg_type(@arg_types){
							if($arg_type ne $argument_types[$index]){
								$is_same = 0;
								last;
							}
							$index ++;
						}
						if($is_same){
							$is_new = 0;
							last;
						}
					}
					if($is_new){
						print "New overload instantiation:";
						$multiple_overload_instantiations ++;
						push(@instantiated_argument_types, [@argument_types]);
						foreach my $arg_type (@argument_types){
							print $arg_type.", ";
						}
						print "\n";
					}
				}
			}
		}
		# register the template name, instantiations, multiple overload instantiations, developer, email, edit time, definition file, line number
		my @local_record = ();
		push(@local_record, $class_name);
		push(@local_record, $instantiations);
		push(@local_record, $multiple_overload_instantiations);
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
		my $filePath = substr($temp_def_file, $skipCharNum);
		push(@local_record, $filePath);
		push(@local_record, $temp_def_line);
		push(@class_temp_record, [@local_record]);
	}
}

## process classes
print $proj_name."-".$version_number."============processing classes\n";
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
	# get the definition info of this class
	my $is_base_class = 0;
	my @hierarchy_rec = ();
	foreach my $ref ($class->ref("C Definein")){
		last unless $ref;
		# if the class is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined class
		my $ref_file = $ref->file->longname();
		$is_user_def_class = 0 if $ref_file =~ /($third_party_lib_path)/;
		# only user-defines classes in C++ files are processed
		last unless $is_user_def_class;
		# filter out the classes having base classes
		my $has_base = 0;
		foreach my $base_ref ($class->refs("C Base")){
			$has_base = 1;
			last;
		}
		last if $has_base;
		# process the classes having derived classes
		foreach my $dev_ref ($class->refs("C Derive")){
			if(!$is_base_class){
				$is_base_class = 1;
				push(@hierarchy_rec, $class_longname);
			}
			my @sub_hierarchy_rec = getSubHierarchy($dev_ref);
			if(scalar(@sub_hierarchy_rec) > 0) {
				push(@hierarchy_rec, [@sub_hierarchy_rec]);
			}
		}
		if($is_base_class){
			$class_def_file = $ref->file->longname();
			$class_def_line = $ref->line();
			@edit_info = getEditInfo($class_def_file, $class_def_line);
		}
		last;
	}
	next unless $is_user_def_class;
	# register the base class name, developer, email, edit time, definition file, line number
	if($is_base_class){
		my @local_record = ();
		push(@local_record, $class_longname);
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
		push(@base_class_info, [@local_record]);
		# record the class hierarchy
		push(@class_hierarchy_record, [@hierarchy_rec]);
		print($class_longname."\n");
	}
}
# ===============================================================================================================================================
## to get the lexical text of an argument
sub getTempArgTexts{
	my ($ref, $temp_name) = @_;
	my @argument_texts = ();
	my @arguments = ();
	my $lex = $ref->lexeme();
	return @argument_texts unless $lex;
	$lex = $ref->lexeme();
	return @argument_texts if $lex->text ne $temp_name;
	do{
		$lex = $lex->next;
		return @argument_texts unless $lex;
	} while ($lex->text !~ /</);
	$lex = $lex->next;
	my $angleBracketCount = 1;
	my $parenCount = 0;
	my $count = 0;
	while ($angleBracketCount && $lex && $count < 20){
	    return @argument_texts if $lex->text =~ /}|{|;/;
	    $parenCount++ if $lex->text eq "(";
	    $parenCount-- if $lex->text eq ")";
	    $angleBracketCount++ if $lex->text eq "<";
	    $angleBracketCount-- if $lex->text eq ">";
	    if($angleBracketCount == 0){
		last;
	    }
	    push(@arguments, $lex);
	    $lex = $lex->next;
	    $count ++;
	}
	return @argument_texts if $count == 20;
	# analyze each argument
	my @filtered_argument = ();
	$parenCount = 0;
	foreach my $arg_lex (@arguments){
		if($arg_lex->text eq "," and $parenCount == 0){
			my $length = @filtered_argument;
			push(@argument_texts, getArgText($length, @filtered_argument));
			@filtered_argument = ();
			next;
		}
		elsif($arg_lex->text eq "("){
			$parenCount ++;
		}
		elsif($arg_lex->text eq ")"){
			$parenCount --;
		}
		push(@filtered_argument, $arg_lex) if $arg_lex->token ne "Whitespace";
	}
	# analyze the last argument
	my $length = @filtered_argument;
	if($length > 0){
		push(@argument_texts, getArgText($length, @filtered_argument));
	}
	return @argument_texts;
}

sub getArgText{
	my $args_length = $_[0];
	my @argument_lexemes = ();
	my $arg_text = "";
	for(my $i = 1; $i <= $args_length; $i ++){
		push(@argument_lexemes, $_[$i]);
	}
	foreach my $lexeme (@argument_lexemes){
		$arg_text .= $lexeme->text;
	}
	return $arg_text;
}

# subprogram to get editing information
sub getEditInfo{
	my $file_name = $_[0];
	my $line_num = $_[1];
	# get git blame info
	my $blame_cmd = "$git_cmd blame -w -L $line_num,+1 \"$file_name\"";
	my $blame_info = `$blame_cmd`;
	# get developer name and editing date from git blame info
	$blame_info =~ /\(((\s|\S)+)\s(\d+)-(\d+)-(\d+)/;
	my ($dev_name, $space, $year, $month, $day) = ($1, $2, $3, $4, $5);
	my $date = $year.$month.$day;
	my @ret_rec = ($dev_name, $date);
	return @ret_rec;
}

# subprogram to get the class hierarchy
sub getSubHierarchy{
	my $dev_ref = $_[0];
	my @hierarchy_rec = ();
	return @hierarchy_rec unless $dev_ref;
	my $class = $dev_ref->ent();
	return @hierarchy_rec unless $class;
	my $class_name = $class->longname();
	push(@hierarchy_rec, $class_name);
	foreach my $ref ($class->refs("C Derive")){
		my @sub_hierarchy_rec = getSubHierarchy($ref);
		if(scalar(@sub_hierarchy_rec) > 0) {
			push(@hierarchy_rec, [@sub_hierarchy_rec]);
		}
	}
	return @hierarchy_rec;
}

# subprogram to print class hierarchy
sub printHierarchy{
	my ($output_file, $depth, @hierarchy_rec) = @_;
	#my @hierarchy_rec = @{$hierarchy_rec_arg};
	my $iter_num = 0;
	foreach my $iter (@hierarchy_rec){
		if($iter_num == 0){	# process current class
			my $class_name = $iter;
			syswrite($output_file,"//$depth:$class_name");
		} else{				# process sub classes
			printHierarchy($output_file,$depth+1,@{$iter});
		}
		$iter_num ++;
	}
}

# write info into excel
# ===============================================================================================================================================
my $output_path = $common_output_path.$proj_name."-".$version_number."_RQ3.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "class template, instantiations, multiple overload instantiations, developer, email, edit time, definition file path, line\n");
foreach my $iter (@class_temp_record){
	my @temp_rec = @{$iter};
	syswrite("metricfile", "$temp_rec[0], //$temp_rec[1], //$temp_rec[2], //$temp_rec[3], //$temp_rec[4], //$temp_rec[5], //$temp_rec[6], //$temp_rec[7]\n");
}
syswrite("metricfile", "\n");
syswrite("metricfile", "base class, developer, email, edit time, definition file path, line, sub-class hierarchy\n");
my $iter_num = 0;
foreach my $iter (@base_class_info){
	my @base_class_rec = @{$iter};
	syswrite("metricfile", "$base_class_rec[0], //$base_class_rec[1], //$base_class_rec[2], //$base_class_rec[3], //$base_class_rec[4], //$base_class_rec[5], ");
	my $cur_rec = $class_hierarchy_record[$iter_num];
	my @hierarchy_rec = @{$cur_rec};
	printHierarchy("metricfile", 0, @hierarchy_rec);
	syswrite("metricfile", "\n");
	$iter_num ++;
}
close("metricfile");
