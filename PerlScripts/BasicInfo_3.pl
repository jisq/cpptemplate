my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/BasicInfo_3/";
my $proj_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/latest version/";
my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

##########################################################
####### detecting the use of new template features  ######
##########################################################
# new function template features
my @variadic_func_temps = ();
my @variadic_func_temp_names = ();

# new class template features
my @variadic_class_temps = ();
my @variadic_class_temp_names = ();
my @alias_class_temps = ();
my @alias_class_temp_names = ();
my $alias_class_temp_num = 0;

# subprogram to check template parameters
sub checkTempParas{
	my $ref = $_[0];
	my $ent_name = $_[1];
	my $ent_kind = $_[2];
	my @temp_paras = ();
	my $check_result = 0;
	my $lex = $ref->lexeme();
	$lex = $lex->previous() while $lex and $lex->text ne ">";
	return unless $lex;
	my @reversed_temp_paras;
	my $para_num = 1;
	my $right_para_num = 1;
	my @cur_para_text;
	while($para_num){
		$lex = $lex->previous();
		last unless $lex;
		if($lex->text eq ">"){
			$para_num ++;
			$right_para_num ++;
		}
		$para_num -- if $lex->text eq "<";
		if(($lex->text eq "," and $para_num == 1) or ($lex->text eq "<" and $para_num == 0)){
			my $cur_para = "";
			my $text_length = @cur_para_text;
			for(my $index = $text_length - 1; $index >= 0; $index --){
				$cur_para .= $cur_para_text[$index];
			}
			push(@reversed_temp_paras, $cur_para);
			@cur_para_text = ();
		}
		elsif($lex->text !~ /\n/){
			push(@cur_para_text, $lex->text);
		}
	}
	return if $para_num;
	$para_num = @reversed_temp_paras;
	for(my $index = $para_num - 1; $index >= 0; $index --){
		my $cur_para = $reversed_temp_paras[$index];
		push(@temp_paras, $cur_para);
	}
	$check_result = checkVariadicParas(@temp_paras);
	if($ent_kind eq "function" and $check_result){
		push(@variadic_func_temps, $ref);
		push(@variadic_func_temp_names, $ent_name);
	} elsif($ent_kind eq "class" and $check_result){
		push(@variadic_class_temps, $ref);
		push(@variadic_class_temp_names, $ent_name);
	}
}

# subprogram to check variadic parameters
sub checkVariadicParas(){
	my @temp_paras = @_;
	foreach my $temp_para (@temp_paras){
		return 1 if $temp_para =~ /\.\.\./;
	}
	return 0;
}

print $proj_name."=============detecting variadic function templates\n";
## process function templates
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	# determine whether it is a valid function template
	if(not defined($value[0])){
		next;
	}
	# if it is a 3rd-party template, jump over
	elsif($func_name =~ /($third_party_lib_prefix)/){
		next;
	}
	# traverse all the refs of this function template
	my $definition_processed = 0;
	my $is_specialized = 0;
	# traverse the refs of this function template
	foreach my $ref ($func->refs()){
		my $ref_file = $ref->file()->longname();
		# process the function template if it is defined in valid C++ files
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# if it is defined, process it
			if($ref_name eq "C Definein"){
				if($definition_processed == 0){
					$definition_processed = 1;
					checkTempParas($ref, $func_name, "function");
				}
			}
		}
	}
}

print $proj_name."=============detecting variadic class templates\n";
## process class templates
processClassTemplates("C Class Template");
processClassTemplates("C Struct Template");
sub processClassTemplates{
	my $ent_kind = shift;
	foreach my $class ($db->ents($ent_kind)){
		my $class_name = $class->longname;
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		# determine whether it is a valid class template
		if(not defined($value[0])){
			next;
		}
		# if it is a 3rd-party template, jump over
		elsif($class_name =~ /($third_party_lib_prefix)/){
			next;
		}
		my $definition_processed = 0;
		my $is_explicitly_specialized = 0;
		my $is_partially_specialized = 0;
		# traverse the refs of this class template
		foreach my $ref ($class->refs()){
			my $ref_file = $ref->file()->longname();
			# process the class template if it is defined in valid C++ files
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				my $ref_name = $ref->kind()->longname();
				# if it is defined, process it
				if($ref_name eq "C Definein"){
					if($definition_processed == 0){
						$definition_processed = 1;
						checkTempParas($ref, $class_name, "class");
					}
				}
			}
		}
	}
}

## process alias class templates
print $proj_name."=============detecting alias class templates\n";
foreach my $file ($db->ents("C Code File")){
	my $file_name = $file->longname();
	if($file_name =~ /\.(C|cc|cpp|cxx)$/ and $file_name !~ /($third_party_lib_path)/){
		my $lexer = $file->lexer();
		my $file_text = "";
		foreach my $lexeme ($lexer->lexemes()) {
		    last unless $lexeme;
		    my $line_text = $lexeme->text;
		    next unless $line_text;
		    $file_text .= $line_text;
		}
		my @match_words = ();
		if(@match_words = ($file_text =~ />((\s|\n)+)using(\s+)(\S+)(\s*)=(\s*)(\S+)</g)){
			my $match_count = scalar(@match_words)/7;
			for(my $index = 0; $index < $match_count; $index ++){
				my $alias_class_name = $match_words[$index*7+3];
				my @cur_alias_rec = ();
				push(@cur_alias_rec, $alias_class_name);
				push(@cur_alias_rec, $file_name);
				push(@alias_class_temps, [@cur_alias_rec]);
				$alias_class_temp_num ++;
			}
		}
	}
}
foreach my $file ($db->ents("C Header File")){
	my $file_name = $file->longname();
	my $is_valid_head_file = 1;
	foreach my $file_unknown ($db->ents("C Unknown Header File")){
		my $file_name_unknown = $file_unknown->longname();
		if($file_name eq $file_name_unknown){
			$is_valid_head_file = 0;
			last;
		}
	}
	if($is_valid_head_file == 0){
		next;
	}
	foreach my $file_unresolved ($db->ents("C Unresolved Header File")){
		my $file_name_unresolved = $file_unresolved->longname();
		if($file_name eq $file_name_unresolved){
			$is_valid_head_file = 0;
			last;
		}
	}
	if($is_valid_head_file == 0){
		next;
	}
	if($file_name =~ /\.(H|h|hh|hpp|hxx)$/ and $file_name !~ /($third_party_lib_path)/){
		my $lexer = $file->lexer();
		my $file_text = "";
		  # regenerate source file from lexemes
		  # add a '@' after each entity name
		foreach my $lexeme ($lexer->lexemes()) {
		    last unless $lexeme;
		    my $line_text = $lexeme->text;
		    next unless $line_text;
		    $file_text .= $line_text;
		}
		my @match_words = ();
		if(@match_words = ($file_text =~ />((\s|\n)+)using(\s+)(\S+)(\s*)=(\s*)(\S+)</g)){
			my $match_count = scalar(@match_words)/7;
			for(my $index = 0; $index < $match_count; $index ++){
				my $alias_class_name = $match_words[$index*7+3];
				my @cur_alias_rec = ();
				push(@cur_alias_rec, $alias_class_name);
				push(@cur_alias_rec, $file_name);
				push(@alias_class_temps, [@cur_alias_rec]);
				$alias_class_temp_num ++;
			}
		}
	}
}

##################################################################
####### detecting old substitutes of new template features  ######
##################################################################
#potential opportunities to use new template features
my %func_temp_rec;
my @potential_variadic_class_temps;
my @variadic_class_temp_names_2;
my @potential_alias_class_temps;
my @potential_alias_temp_names;

print $proj_name."=============detecting potential variadic function templates\n";
## detect potential variadic function templates
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	# determine whether it is a valid function template
	if(not defined($value[0])){
		if($func_name !~ /$namespace_mark/){
			next;
		}
		if($func_name !~ /$std_lib_prefix/ and $func_name !~ /($third_party_lib_prefix)/){
			next;
		}
	}
	# if it is a 3rd-party template, jump over
	elsif($func_name =~ /($third_party_lib_prefix)/){
		next;
	}
	# traverse all the refs of this function template
	my $use_count = 0;
	my $ref_filename = "";
	my $line = -1;
	my $column = -1;
	my @temp_check_result;
	my $no_friend_found = 1;
	# traverse the refs of this function template
	foreach my $ref ($func->refs()){
		my $ref_file = $ref->file()->longname();
		# process the function template if it is defined in valid C++ files
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# if it is defined, process it
			if($ref_name eq "C Definein"){
				if(exists $func_temp_rec{$func_name}){
					push(@{$func_temp_rec{$func_name}}, $ref);
				} else{
					my @cur_rec = ();
					push(@cur_rec, $ref);
					$func_temp_rec{$func_name} = \@cur_rec;
				}
			}
		}
	}
}

print $proj_name."=============detecting potential variadic class templates\n";
## process class templates
processClassTemplates_2("C Class Template");
processClassTemplates_2("C Struct Template");
sub processClassTemplates_2{
	my $ent_kind = $_[0];
	foreach my $class ($db->ents($ent_kind)){
		my $class_name = $class->longname;
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		# determine whether it is a valid class template
		if(not defined($value[0])){
			if($class_name !~ /$namespace_mark/){
				next;
			}
			if($class_name !~ /$std_lib_prefix/ and $class_name !~ /($third_party_lib_prefix)/){
				next;
			}
		}
		# if it is a 3rd-party template, jump over
		elsif($class_name =~ /($third_party_lib_prefix)/){
			next;
		}
		my $definition_processed = 0;
		my $use_count = 0;
		my $derivation_count = 0;
		my $ref_filename = "";
		my $line = -1;
		my $column = -1;
		# traverse the refs of this class template
		foreach my $ref ($class->refs()){
			my $ref_file = $ref->file()->longname();
			# process the class template if it is defined in valid C++ files
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				my $ref_name = $ref->kind()->longname();
				# if it is defined, process it
				if($ref_name eq "C Definein"){
					if($definition_processed == 0){
						$definition_processed = 1;
						checkTempParas_2($ref, $class_name);
					}
				}
			}
		}
	}
}

# subprogram to check template parameters
sub checkTempParas_2{
	my $ref = $_[0];
	my $class_temp_name = $_[1];
	my @temp_paras = ();
	my $lex = $ref->lexeme();
	$lex = $lex->previous() while $lex and $lex->text ne ">";
	return unless $lex;
	my @reversed_temp_paras;
	my $para_num = 1;
	my $right_para_num = 1;
	my @cur_para_text;
	while($para_num){
		$lex = $lex->previous();
		last unless $lex;
		if($lex->text eq ">"){
			$para_num ++;
			$right_para_num ++;
		}
		$para_num -- if $lex->text eq "<";
		if(($lex->text eq "," and $para_num == 1) or ($lex->text eq "<" and $para_num == 0)){
			my $cur_para = "";
			my $text_length = @cur_para_text;
			for(my $index = $text_length - 1; $index >= 0; $index --){
				$cur_para .= $cur_para_text[$index];
			}
			push(@reversed_temp_paras, $cur_para);
			@cur_para_text = ();
		}
		elsif($lex->text !~ /\n/){
			push(@cur_para_text, $lex->text);
		}
	}
	return if $para_num;
	$para_num = @reversed_temp_paras;
	for(my $index = $para_num - 1; $index >= 0; $index --){
		my $cur_para = $reversed_temp_paras[$index];
		push(@temp_paras, $cur_para);
	}
	if(checkAllDefaultParas(@temp_paras)){
		push(@potential_variadic_class_temps, $ref);
		push(@variadic_class_temp_names_2, $class_temp_name);
	}

}

# subprogram to check all default parameters
sub checkAllDefaultParas(){
	my @temp_paras = @_;
	my $para_count = 0;
	foreach my $temp_para (@temp_paras){
		return 0 if $temp_para !~ /=/;
		$para_count ++;
	}
	return 1 if $para_count > 1;
	return 0;
}

print $proj_name."=============detecting potential alias templates\n";
## detect potential opportunities to use alias templates
foreach my $type ($db->ents("C Typedef Type")){
	# print $type->name."\n";
	foreach my $ref ($type->refs()){
		my $ref_name = $ref->kind()->longname();
		my $ref_file = $ref->file()->longname();
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			if($ref_name eq "C Definein"){
				my $line = $ref->line();
				my $column = $ref->column();
				my $lex = $ref->lexeme();
				$lex = $lex->previous() while $lex and $lex->text ne ">" and $lex->text ne "typedef";
				next unless $lex;
				next if $lex->text eq "typedef";
				# to get template arguments
				my @argument_texts = getTempArgTexts($ref);
				# to get the lex refering to template name
				$lex = $lex->previous;
				next unless $lex;
				my $parenCount = 1;
				while ($parenCount and $lex){
				    $parenCount++ if $lex->text eq ">";
				    $parenCount-- if $lex->text eq "<";
				    if($parenCount == 0 or $lex->text eq "typedef"){
					last;
				    }
				    $lex = $lex->previous;
				}
				next if $parenCount > 0;
				$lex = $lex->previous();
				next unless $lex;
				$lex = $lex->previous() while $lex and $lex->token eq "Whitespace";
				next unless $lex;
				# to get template parameters
				my @parameter_texts = ();
				my $cur_ent = $lex->ent();
				next unless $cur_ent;
				foreach my $temp_ref ($cur_ent->refs()){
					my $temp_ref_name = $temp_ref->kind()->longname();
					# if it is defined, process it
					if($temp_ref_name eq "C Definein"){
						@parameter_texts = getTempParaTexts($temp_ref);
					}
				}
				if(length(@parameter_texts) == length(@argument_texts)){
					for (my $i = 0; $i < length(@parameter_texts); $i++) {
						if($parameter_texts[$i] eq $argument_texts[$i]){
							push(@potential_alias_class_temps, $ref);
							push(@potential_alias_temp_names, $type->name);
							last;
						}
					}
				}
			}
		}
	}
}

## to get the lexical texts of template arguments
sub getTempArgTexts{
	my $ref = $_[0];
	my @temp_paras = ();
	my $lex = $ref->lexeme();
	$lex = $lex->previous() while $lex and $lex->text ne ">";
	return unless $lex;
	my @reversed_temp_paras;
	my $para_num = 1;
	my $right_para_num = 1;
	my @cur_para_text;
	while($para_num){
		$lex = $lex->previous();
		last unless $lex;
		if($lex->text eq ">"){
			$para_num ++;
			$right_para_num ++;
		}
		$para_num -- if $lex->text eq "<";
		if(($lex->text eq "," and $para_num == 1) or ($lex->text eq "<" and $para_num == 0)){
			my $cur_para = "";
			my $text_length = @cur_para_text;
			for(my $index = $text_length - 1; $index >= 0; $index --){
				$cur_para .= $cur_para_text[$index];
			}
			push(@reversed_temp_paras, $cur_para);
			@cur_para_text = ();
		}
		elsif($lex->text !~ /\n/){
			push(@cur_para_text, $lex->text);
		}
	}
	return if $para_num;
	$para_num = @reversed_temp_paras;
	for(my $index = $para_num - 1; $index >= 0; $index --){
		my $cur_para = $reversed_temp_paras[$index];
		push(@temp_paras, $cur_para);
	}
	return @temp_paras;
}

## to get the lexical texts of template parameters
sub getTempParaTexts{
	my $ref = $_[0];
	my @temp_paras = ();
	my $lex = $ref->lexeme();
	$lex = $lex->previous() while $lex and $lex->text ne ">";
	return unless $lex;
	my @reversed_temp_paras;
	my $para_num = 1;
	my $right_para_num = 1;
	my @cur_para_text;
	while($para_num){
		$lex = $lex->previous();
		last unless $lex;
		if($lex->text eq ">"){
			$para_num ++;
			$right_para_num ++;
		}
		$para_num -- if $lex->text eq "<";
		if(($lex->text eq "," and $para_num == 1) or ($lex->text eq "<" and $para_num == 0)){
			my $cur_para = "";
			my $text_length = @cur_para_text;
			for(my $index = $text_length - 1; $index >= 0; $index --){
				$cur_para .= $cur_para_text[$index];
			}
			push(@reversed_temp_paras, $cur_para);
			@cur_para_text = ();
		}
		elsif($lex->text !~ /\n/){
			push(@cur_para_text, $lex->text);
		}
	}
	return if $para_num;
	$para_num = @reversed_temp_paras;
	for(my $index = $para_num - 1; $index >= 0; $index --){
		my $cur_para = $reversed_temp_paras[$index];
		my $processed_para = $cur_para;
		my @match_words = ();
		if(@match_words = ($processed_para =~ /typename(\s+)(\S+)/g)){
			$processed_para = $match_words[1];
		}
		@match_words = ();
		if(@match_words = ($processed_para =~ /class(\s+)(\S+)/g)){
			$processed_para = $match_words[1];
		}
		@match_words = ();
		if(@match_words = ($processed_para =~ /(\S+)(\s+)=/g)){
			$processed_para = $match_words[0];
		}
		push(@temp_paras, $processed_para);
	}
	return @temp_paras;
}

# ===============================================================================================================================================
# write information into excel
my $output_path = $common_output_path.$proj_name."_BasicInfo_3.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "variadic function templates, variadic class templates, alias class templates\n");
my $variadic_func_temp_num = scalar(@variadic_func_temps);
my $variadic_class_temp_num = scalar(@variadic_class_temps);
syswrite("metricfile", "$variadic_func_temp_num, //$variadic_class_temp_num, //$alias_class_temp_num\n");
syswrite("metricfile", "\n");
syswrite("metricfile", "old substitutes of variadic function templates, old substitutes of variadic class templates, old substitutes of alias class templates\n");
my $os_vft_num = 0;
foreach my $key (keys %func_temp_rec){
	my @cur_rec = @{$func_temp_rec{$key}};
	my $count = 0;
	foreach my $ref (@cur_rec){
		$count ++;
	}
	if($count > 4){
		$os_vft_num ++;
	}
}
my $os_vct_num = scalar(@potential_variadic_class_temps);
my $os_at_num = scalar(@potential_alias_class_temps);
syswrite("metricfile", "$os_vft_num, //$os_vct_num, //$os_at_num\n");
syswrite("metricfile", "\n");

## write detailed information about the usages of new template features
# variadic function templates
syswrite("metricfile", "variadic function templates\n");
my $index = 0;
foreach my $ref (@variadic_func_temps){
	my $ref_filename = $ref->file->longname;
	my $skipCharNum = length($proj_path);
	my $filePath = substr($ref_filename, $skipCharNum);
	my $ref_line = $ref->line;
	my $func_name = $variadic_func_temp_names[$index];
	syswrite("metricfile", "$func_name, //$filePath, //$ref_line\n");
	$index ++;
}
syswrite("metricfile", "\n");
# variadic class templates
syswrite("metricfile", "variadic class templates\n");
$index = 0;
foreach my $ref (@variadic_class_temps){
	my $ref_filename = $ref->file->longname;
	my $skipCharNum = length($proj_path);
	my $filePath = substr($ref_filename, $skipCharNum);
	my $ref_line = $ref->line;
	my $class_name = $variadic_class_temp_names[$index];
	syswrite("metricfile", "$class_name, //$filePath, //$ref_line\n");
	$index ++;
}
syswrite("metricfile", "\n");
# alias class templates
syswrite("metricfile", "alias class templates\n");
my @alias_temp_edit_info = ();
foreach my $a_row (@alias_class_temps){
	my @alias_class_temp_rec = @{$a_row};
	my $alias_class_name = $alias_class_temp_rec[0];
	my $file_name = $alias_class_temp_rec[1];
	# read the source file, to get the line number of alias use
	open(my $fh_source, $file_name) or die "Could not open source file\n";
	my $line_num = 0;
	while(my $source_text = <$fh_source>){
		$line_num ++;
		if($source_text =~ /((\s|\n)*)using(\s+)$alias_class_name(\s*)=/){
			my $has_rec = 0;
			foreach my $rec (@alias_temp_edit_info){
				my @this_alias_temp_rec = @{$rec};
				my $this_alias_temp_name = $this_alias_temp_rec[0];
				my $this_alias_temp_file_name = $this_alias_temp_rec[1];
				my $this_alias_temp_line_num = $this_alias_temp_rec[2];
				if($alias_class_name eq $this_alias_temp_name and $file_name eq $this_alias_temp_file_name and $line_num eq $this_alias_temp_line_num){
					$has_rec = 1;
					last;
				}
			}
			next if $has_rec;
			# update alias temp info
			my @new_alias_temp_rec = ($alias_class_name, $file_name, $line_num);
			push(@alias_temp_edit_info, [@new_alias_temp_rec]);
			last;
		}
	}
	close($fh_source);
}
foreach my $rec (@alias_temp_edit_info){
	my @this_alias_temp_rec = @{$rec};
	my $skipCharNum = length($proj_path);
	my $filePath = substr($this_alias_temp_rec[1], $skipCharNum);
	syswrite("metricfile", "$this_alias_temp_rec[0], //$filePath, //$this_alias_temp_rec[2]\n");
}
syswrite("metricfile", "\n");

## write detailed information about the usages of old substitutes of new template features
# potential variadic function templates
syswrite("metricfile", "potential variadic function templates\n");
foreach my $key (keys %func_temp_rec){
	my @cur_rec = @{$func_temp_rec{$key}};
	my $count = 0;
	foreach my $ref (@cur_rec){
		$count ++;
	}
	if($count > 4){
		foreach my $ref (@cur_rec){
			print $ref->file->longname." ".$ref->line." "."\n";
			my $ref_filename = $ref->file->longname;
			my $skipCharNum = length($proj_path);
			my $filePath = substr($ref_filename, $skipCharNum);
			my $ref_line = $ref->line;
			syswrite("metricfile", "$key, //$filePath, //$ref_line\n");
		}
	}
}
syswrite("metricfile", "\n");
# potential variadic class templates
syswrite("metricfile", "potential variadic class templates\n");
$index = 0;
foreach my $ref (@potential_variadic_class_temps){
	my $ref_filename = $ref->file->longname;
	my $skipCharNum = length($proj_path);
	my $filePath = substr($ref_filename, $skipCharNum);
	my $ref_line = $ref->line;
	my $class_temp_name = $variadic_class_temp_names_2[$index];
	syswrite("metricfile", "$class_temp_name, //$filePath, //$ref_line\n");
	$index ++;
}
syswrite("metricfile", "\n");
# potential alias class templates
syswrite("metricfile", "potential alias class templates\n");
$index = 0;
foreach my $ref (@potential_alias_class_temps){
	my $ref_filename = $ref->file->longname;
	my $skipCharNum = length($proj_path);
	my $filePath = substr($ref_filename, $skipCharNum);
	my $ref_line = $ref->line;
	my $ref_column = $ref->column;
	my $class_temp_name = $potential_alias_temp_names[$index];
	syswrite("metricfile", "$class_temp_name, //$filePath, //$ref_line\n");
	$index ++;
}
close("metricfile");