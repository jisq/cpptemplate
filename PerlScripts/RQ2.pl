
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ2/".$proj_name."/";
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
my @file_names = ();
my @func_temp_record = ();
my @gflm_record = ();
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

#################################
## process function templates  ##
#################################
print $proj_name."-".$version_number."_".$date."==========process function templates\n";
foreach my $func ($db->ents("C Function Template")){
	my $func_temp_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_template = 1;
	my @edit_info = ("", "");
	my $call_count = 0;
	my $multiple_overload_instantiations = 0;
	my @instantiated_argument_types = ();
	# to determine whether it is a library template
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party template
	elsif($func_temp_name =~ /($third_party_lib_prefix)/){
		$is_user_def_template = 0;
	}
	my $defined_in_cpp = 1;
	my $temp_def_file = "";
	my $temp_def_line = -1;
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
		# if the template is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined template
		if($ref_name eq "C Definein"){
			my $ref_file = $ref->file->longname();
			$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
			$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
			$temp_def_file = $ref->file->longname();
			$temp_def_line = $ref->line();
			@edit_info = getEditInfo($temp_def_file, $temp_def_line);
			last;
		}
	}
	# only user-defines function templates in C++ files are processed
	next unless $is_user_def_template;
	next unless $defined_in_cpp;
	# to traverse the refs of this function template
	foreach my $ref ($func->refs()){
		my $ref_file = $ref->file()->longname();
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# if the function template is called
			if($ref_name eq "C Callby"){
				$call_count ++;
				# to analyze whether the template parameters are instantiated with different argument types
				my @argument_types = ();
				my $line = $ref->line();
				my $column = $ref->column();
				if($ref_file and $line and $column){
					@argument_types = getArgTypes($ref, $func_temp_name);
				}
				# if no argument is found
				next if @argument_types == 0;
				# if there is any argument type not resolved, then jump over
				my $has_unresolved = 0;
				foreach my $arg_type (@argument_types){
					if($arg_type eq "#NotResolved#"){
						$has_unresolved = 1;
						last;
					}
				}
				next if $has_unresolved;
				# if different argument types are found
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
					$multiple_overload_instantiations ++;
					push(@instantiated_argument_types, [@argument_types]);
				}
			}
		}
	}
	# register the template name, call count, multiple overload instantiations, developer, email, edit time, definition file, line number
	my @local_record = ();
	push(@local_record, $func_temp_name);
	push(@local_record, $call_count);
	if($call_count > 0 && $multiple_overload_instantiations == 0){
		$multiple_overload_instantiations ++;
	}
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
	push(@func_temp_record, [@local_record]);
	print("func_temp_name=", $func_temp_name," call_count=", $call_count, ", multiple_overload_instantiations=", $multiple_overload_instantiations, "\n");
	print("	dev_name=",  $dev_name, "dev_email=", $dev_email,", edit_time=", $edit_time,"\n");
	print(" ",$temp_def_file, ", line=", $temp_def_line,"\n");
}

#################################
## tranverse all macros        ##
#################################
# traversing all C++ files
foreach my $file ($db->ents("C Code File")){
	my $fname = $file->longname();
	if($fname =~ /\.(C|cc|cpp|cxx)$/ and $fname !~ /($third_party_lib_path)/){
		print $fname."\n";
		my $skipCharNum = length($proj_path);
		my $filePath = substr($fname, $skipCharNum);
		push(@file_names, $filePath);
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
		print $fname."\n";
		my $skipCharNum = length($proj_path);
		my $filePath = substr($fname, $skipCharNum);
		push(@file_names, $filePath);
	}
}
print $proj_name."-".$version_number."_".$date."==========process generic function-like macros\n";
foreach my $macro ($db->ents("C Macro Functional")) {
	my $macro_name = $macro->longname();
	print $proj_name."-".$version_number."_".$date."=========\n".$macro_name."\n";
	my $macro_def_file_path = "";
	my $macro_def_line = -1;
	my $uses = 0;
	my $multiple_overload_instantiations = 0;
	my @instantiated_argument_types = ();
	my @edit_info = ("", "");
	# determine whether the macro is defined in C++ files
	my $is_valid_macro = 0;
	my $macro_def_file = "";
	foreach my $ref ($macro->refs()){
		my $ref_name = $ref->kind()->longname();
		if($ref_name eq "C Definein"){
			$macro_def_file = $ref->file()->longname();
			if($macro_def_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $macro_def_file !~ /($third_party_lib_path)/){
				my $skipCharNum = length($proj_path);
				my $filePath = substr($macro_def_file, $skipCharNum);
				foreach my $fname (@file_names){
					if($fname eq $filePath){
						$is_valid_macro = 1;
						$macro_def_file_path = $filePath;
						$macro_def_line = $ref->line();					
						last;
					}
				}
			}
			last;
		}
	}
	# next if it is not a valid C++ macro
	next unless $is_valid_macro;
	# to find out generic function-like macros
	foreach my $ref ($macro->refs()){
		my $ref_name = $ref->kind()->longname();
		if($ref_name eq "C Useby"){
			my $ref_file = $ref->file()->longname();
			my $is_cpp_ref_file = 0;
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				$is_cpp_ref_file = 1;
			}
			next if $is_cpp_ref_file == 0;
			$uses ++;
			my $line = $ref->line();
			my $column = $ref->column();
			my @argument_types = ();
			if($ref_file and $line and $column){
				@argument_types = getArgTypes($ref, $macro_name);
			}
			my $len = @argument_types;
			# no argument types found
			next if $len == 0;
			# if there is any argument type not resolved, then jump over
			my $has_unresolved = 0;
			foreach my $arg_type (@argument_types){
				if($arg_type eq "#NotResolved#"){
					$has_unresolved = 1;
					last;
				}
			}
			next if $has_unresolved;
			# if different argument types are detected
			my $is_new = 1;
			foreach my $aref (@instantiated_argument_types){
				my @arg_types = @{$aref};
				my $arg_types_len = @arg_types;
				my $argument_types_len = @argument_types;
				next if $arg_types_len != $argument_types_len;
				my $is_same = 1;
				my $index = 0;
				foreach my $arg_type (@arg_types){
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
				$multiple_overload_instantiations ++;
				push(@instantiated_argument_types, [@argument_types]);
			}
		}
	}
	# get the edit info of the macro
	if($multiple_overload_instantiations > 1){
		@edit_info = getEditInfo($macro_def_file, $macro_def_line);
	} else{
		next;
	}
	# register the macro name, call count, multiple overload instantiations, developer, email, edit time, definition file, line number
	my @local_record = ();
	push(@local_record,$macro_name);
	push(@local_record,$uses);
	push(@local_record,$multiple_overload_instantiations);
	my $dev_name = $edit_info[0];
	my $dev_email = "";
	if(exists($dev_email_rec{$dev_name})){
		$dev_email = $dev_email_rec{$dev_name};
	}
	my $edit_time = $edit_info[1];
	push(@local_record, $dev_name);
	push(@local_record, $dev_email);
	push(@local_record, $edit_time);
	push(@local_record, $macro_def_file_path);
	push(@local_record, $macro_def_line);
	push(@gflm_record, [@local_record]);
	print("GFLM_name=", $macro_name," uses=", $uses, ", multiple_overload_instantiations=", $multiple_overload_instantiations, "\n");
	print("	dev_name=",  $dev_name, "dev_email=", $dev_email,", edit_time=", $edit_time,"\n");
	print(" ",$macro_def_file_path, ", line=", $macro_def_line,"\n");
}

#################################################
## process functions implemented with (void*)  ##
#################################################
my @func_temp_ids = ();
foreach my $func_temp ($db->ents("C Function Template")){
	my $id = $func_temp->id();
	push(@func_temp_ids, $id);
}
print $proj_name."-".$version_number."_".$date."==========process functions\n";
foreach my $func ($db->ents("C Function")){
	# determine whether the function is a template
	my $id = $func->id();
	next if (grep { $_ eq $id } @func_temp_ids);
	# process the function
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_func = 1;
	my @edit_info = ("", "");
	my $call_count = 0;
	my $multiple_overload_instantiations = 0;
	my @instantiated_argument_types = ();
	# to determine whether it is a library function
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party function
	elsif($func_name =~ /($third_party_lib_prefix)/){
		$is_user_def_func = 0;
	}
	next unless $is_user_def_func;
	my $defined_in_cpp = 1;
	my $func_def_file = "";
	my $func_def_line = -1;
	my $has_void_ptr_para = 0;
	 # get list of refs that define a parameter entity
    foreach my $param ($func->ents("Define","Parameter")) {
		my $para_type = $param->type();
		# check whether there is a (void*) parameter
		if($para_type =~ /(.*)void(\s*)(\*)(.*)/){
			print($func_name."has a para type of void*\n");
			$has_void_ptr_para = 1;
			last;
		}
    }
	next unless $has_void_ptr_para;
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
				# to analyze whether the (void*) parameters are instantiated with different argument types
				my @argument_types = ();
				my $line = $ref->line();
				my $column = $ref->column();
				if($ref_file and $line and $column){
					@argument_types = getArgTypes($ref, $func_name);
				}
				# if no argument is found
				next if @argument_types == 0;
				# if there is any argument type not resolved, then jump over
				my $has_unresolved = 0;
				foreach my $arg_type (@argument_types){
					if($arg_type eq "#NotResolved#"){
						$has_unresolved = 1;
						last;
					}
				}
				next if $has_unresolved;
				# if different argument types are found
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
					$multiple_overload_instantiations ++;
					push(@instantiated_argument_types, [@argument_types]);
				}
			}
		}
	}
	# register the function name, call count, multiple overload instantiations, developer, email, edit time, definition file, line number
	my @local_record = ();
	push(@local_record, $func_name);
	push(@local_record, $call_count);
	if($call_count > 0 && $multiple_overload_instantiations == 0){
		$multiple_overload_instantiations ++;
	}
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
	my $filePath = substr($func_def_file, $skipCharNum);
	push(@local_record, $filePath);
	push(@local_record, $func_def_line);
	push(@func_record, [@local_record]);
	print("func_name=", $func_name," call_count=", $call_count, ", multiple_overload_instantiations=", $multiple_overload_instantiations, "\n");
	print("	dev_name=",  $dev_name, "dev_email=", $dev_email,", edit_time=", $edit_time,"\n");
	print(" ",$func_def_file, ", line=", $func_def_line,"\n");
}

# ===============================================================================================================================================
## subprogram to obtain the argument types
sub getArgTypes{
	my ($ref, $subprogram_name) = @_;	
	my @argument_types = ();
	my @arguments = ();
	my $lex = $ref->lexeme();
	return @argument_types unless $lex;
	while($lex->text ne $subprogram_name and $lex->text ne ";"){
		$lex = $lex->next;
		return @argument_types unless $lex;
	}
	if($lex->text eq ";"){
		return @argument_types;
	}
	do{
	    $lex = $lex->next;
	    return @argument_types unless $lex;
	} while ($lex->text ne "(" && $lex->text ne ";");
	return @argument_types if $lex->text eq ";";
	$lex = $lex->next;
	my $parenCount = 1;
	my $count = 0;  #Catch runaways, just in case
	while ($parenCount && $lex && $count < 30){
	    $parenCount++ if $lex->text eq "(";
	    $parenCount-- if $lex->text eq ")";
	    if($parenCount == 0){
		last;
	    }
	    push(@arguments, $lex);
	    $lex = $lex->next;
	    $count ++;
	}
	# analyze each argument
	my @filtered_argument = ();
	print $ref->file->longname." ".$ref->line." ".$ref->column."\n";
	$parenCount = 0;
	foreach my $arg_lex (@arguments){
		if($arg_lex->text eq "," and $parenCount == 0){
			my $length = @filtered_argument;
			push(@argument_types, getArgType($length, @filtered_argument));
			foreach my $arg_lex (@filtered_argument){
				print $arg_lex->text."#";
			}
			print "\n";
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
		push(@argument_types, getArgType($length, @filtered_argument));
		foreach my $arg_lex (@filtered_argument){
				print $arg_lex->text."#";
		}
			print "\n";
	}
	foreach my $arg_type (@argument_types){
		print $arg_type.", ";
	}
	return @argument_types;
}

sub getArgType(){
	my $args_length = $_[0];
	my @argument_lexemes = ();
	for(my $i = 1; $i <= $args_length; $i ++){
		push(@argument_lexemes, $_[$i]);
	}
	# the argument is composed of only one expression
	if($args_length == 1){
		my $lexeme = $argument_lexemes[0];
		if($lexeme->token eq "String"){
			return "std::string";
		} elsif($lexeme->token eq "Literal"){
			return "double" if length($lexeme->text) > 1 and $lexeme->text =~ /./;
			return "int" if length($lexeme->text) > 1;
			return "int" if length($lexeme->text) == 1 and $lexeme->text =~ /\d/;
			return "char" if length($lexeme->text) == 1 and $lexeme->text =~ /\D/;
		} elsif($lexeme->token eq "Identifier"){
			my $ent = $lexeme->ent();
			return "#NotResolved#" unless $ent;
			return $ent->type;
		} elsif($lexeme->token eq "Operator"){
			next;
		} elsif($lexeme->token eq "Preprocessor"){
			return "#NotResolved#";
		}
	}
	# the argument consists of several expressions
	my $cur_arg_type = "#NotResolved#";
	foreach my $lexeme (@argument_lexemes){
		# function call
		if($lexeme->text eq "("){
			next;
		}
		# identifier
		elsif($lexeme->token eq "Identifier"){
			my $ent = $lexeme->ent();
			return "#NotResolved#" unless $ent;
			$cur_arg_type = $ent->type;
		}
		# attribute access
		elsif($lexeme->text eq "." or $lexeme->text eq "->"){
			next;
		}
		# array access
		elsif($lexeme->text eq "["){
			if($cur_arg_type ne "#NotResolved#"){
				my $container_type = $cur_arg_type;
				print "container_type: $container_type\n";
				# to match array access
				if($container_type =~ /\(/){
					$container_type =~ /(\s+)\((\s+)\)/;
					return $1 if $1;
				}
				# to match container access
				if($container_type =~ /</){
					$container_type =~ /(\s+)<(\s+)>/;
					return $2 if $2;
				}
				return "#NotResolved#";
			}
		}
		# arithmetic operations
		elsif($lexeme->token eq "Operator"){
			next;
		}
		elsif($lexeme->token eq "String"){
			$cur_arg_type = "std::string";
		}
		elsif($lexeme->token eq "Literal"){
			$cur_arg_type = "double" if length($lexeme->text) > 1 and $lexeme->text =~ /./;
			$cur_arg_type = "int" if length($lexeme->text) > 1;
			print $lexeme->text."**\n";
			$cur_arg_type = "int" if length($lexeme->text) == 1 and $lexeme->text =~ /\d/;
			$cur_arg_type = "char" if length($lexeme->text) == 1 and $lexeme->text =~ /\D/;
		}
	}
	return $cur_arg_type;
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

# ===============================================================================================================================================
# write info into excel
my $output_path = $common_output_path.$proj_name."-".$version_number."_RQ2.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "function template, instantiations, multiple overload instantiations, developer, email, edit time, definition file path, line\n");
foreach my $iter (@func_temp_record){
	my @temp_rec = @{$iter};
	syswrite("metricfile", "$temp_rec[0], //$temp_rec[1], //$temp_rec[2], //$temp_rec[3], //$temp_rec[4], //$temp_rec[5], //$temp_rec[6], //$temp_rec[7]\n");
}
syswrite("metricfile", "\n");
syswrite("metricfile", "generic function-like macro, instantiations, multiple overload instantiations, developer, email, edit time, definition file path, line\n");
foreach my $iter (@gflm_record){
	my @gflm_rec = @{$iter};
	syswrite("metricfile", "$gflm_rec[0], //$gflm_rec[1], //$gflm_rec[2], //$gflm_rec[3], //$gflm_rec[4], //$gflm_rec[5], //$gflm_rec[6], //$gflm_rec[7]\n");
}
syswrite("metricfile", "\n");
syswrite("metricfile", "function implemented with void*, instantiations, multiple overload instantiations, developer, email, edit time, definition file path, line\n");
foreach my $iter (@func_record){
	my @func_rec = @{$iter};
	syswrite("metricfile", "$func_rec[0], //$func_rec[1], //$func_rec[2], //$func_rec[3], //$func_rec[4], //$func_rec[5], //$func_rec[6], //$func_rec[7]\n");
}
syswrite("metricfile", "\n");
close("metricfile");