
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/RQ1/";
my $proj_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/latest version/";

my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my @func_temp_record = ();
my @class_temp_record = ();
my @class_names = ();

## process class templates
print $proj_name."====================================processing class templates\n";
process_class_templates("C Class Template");
process_class_templates("C Struct Template");

## process function templates
print $proj_name."====================================processing function templates\n";
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_template = 1;
	my $multiple_overload_instantiations = 0;
	my $call_count = 0;
	my $loc = 0;
	my @instantiated_argument_types = ();
	# to determine whether it is a library template
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party template
	elsif($func_name =~ /($third_party_lib_prefix)/){
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
			last;
		}
	}
	# only user-defined freestanding function templates in C++ files are processed
	next unless $is_user_def_template;
	next unless $defined_in_cpp;
	$loc = $value[0];
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
	# register the template name, call count, multiple overload instantiations, loc, definition file, line number
	my @local_record = ();
	push(@local_record, $func_name);
	push(@local_record, $call_count);
	if($call_count > 0 && $multiple_overload_instantiations == 0){
		$multiple_overload_instantiations ++;
	}
	push(@local_record, $multiple_overload_instantiations);
	push(@local_record, $loc);
	my $skipCharNum = length($proj_path);
	my $filePath = substr($temp_def_file, $skipCharNum);
	push(@local_record, $filePath);
	push(@local_record, $temp_def_line);
	push(@func_temp_record, [@local_record]);
}

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
		my $temp_def_file = "";
		my $temp_def_line = -1;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# if the template is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined template
			if($ref_name eq "C Definein"){
				my $ref_file = $ref->file->longname();
				$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
				$temp_def_file = $ref->file->longname();
				$temp_def_line = $ref->line();
				last;
			}
		}
		# only user-defined class templates in C++ files are processed
		next unless $is_user_def_template;
		next unless $defined_in_cpp;
		$loc = $value[0];
		# traverse the refs of this class template
		my $definition_processed = 0;
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
		# register the template name, instantiations, multiple overload instantiations, loc, definition file, line number
		my @local_record = ();
		push(@local_record, $class_name);
		push(@local_record, $instantiations);
		push(@local_record, $multiple_overload_instantiations);
		push(@local_record, $loc);
		my $skipCharNum = length($proj_path);
		my $filePath = substr($temp_def_file, $skipCharNum);
		push(@local_record, $filePath);
		push(@local_record, $temp_def_line);
		push(@class_temp_record, [@local_record]);
	}
}

# ===============================================================================================================================================
## to determine the argument types
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

# write info into excel
# ===============================================================================================================================================
my $output_path = $common_output_path.$proj_name.".csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "class template, instantiations, multiple overload instantiations, loc, definition file path, line\n");
foreach my $iter (@class_temp_record){
	my @temp_rec = @{$iter};
	syswrite("metricfile", "$temp_rec[0], //$temp_rec[1], //$temp_rec[2], //$temp_rec[3], //$temp_rec[4], //$temp_rec[5]\n");
}

syswrite("metricfile", "\n");
syswrite("metricfile", "function template, instantiations, multiple overload instantiations, loc, definition file path, line\n");
foreach my $iter (@func_temp_record){
	my @temp_rec = @{$iter};
	syswrite("metricfile", "$temp_rec[0], //$temp_rec[1], //$temp_rec[2], //$temp_rec[3], //$temp_rec[4], //$temp_rec[5]\n");
}
syswrite("metricfile", "\n");

close("metricfile");
