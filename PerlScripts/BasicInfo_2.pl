
my $common_output_path = "/media/data/home/wudi/CPPTemplateExperiment_TOSEM/Results/TemporalFiles/BasicInfo/BasicInfo_2/";
my $proj_path = "/media/data/home/wudi/CPPTemplateExperiment_NewPaper_revised/Projects/".$proj_name."/latest version/";

my $namespace_mark = "::";
my $third_party_lib_prefix = "boost::|bdlt::|dlib::|juce::|loki::|Reason::|folly::|cxxomfort::|scy::|Upp::|caf::|glm::|miniupnpc::|quesoglc::|sdl::|WTL::|scintilla::|leveldb::
|json_spirit::|ATL::|vcg::|hull::|yaSSL::|TaoCrypt::|KFS::|antlr::|dena::|open_query::|agg::|Imath::|Eigen::|sg::|carve::|libmv::|TNT::|BasicVector::|Py::|utf8::";
my $std_lib_prefix = "std::";
my $third_party_lib_path = "ext/|json/|leveldb/|TabbingFramework/|thirdparty/|3rdparty/|3rdParty/|third_party/|ThirdParty/|OublietteImport/Extern/|external/|extra/|zlib/
|libevent/|libmysql/|libmysqld/|libservices/|contrib/|SageIII/qtools/|libmd5/|utf8/|wxWidgets-2.9.1/|libclamav/";

my $class_temp_definitions = 0;
my $class_temp_instantiations = 0;
my $func_temp_definitions = 0;
my $func_temp_instantiations = 0;

## process class templates
process_class_templates("C Class Template");
process_class_templates("C Struct Template");

## process function templates
foreach my $func ($db->ents("C Function Template")){
	my $func_name = $func->longname();
	my @metriclist = ("AltCountLineCode");
	my @value = $func->metric(@metriclist);
	my $is_user_def_template = 1;
	# to determine whether it is a library template
	if(not defined($value[0])){
		next;
	}
	# to determine whether it is a 3rd-party template
	elsif($func_name =~ /($third_party_lib_prefix)/){
		$is_user_def_template = 0;
	}
	my $defined_in_cpp = 1;
	foreach my $ref ($func->refs()){
		my $ref_name = $ref->kind()->longname();
		# if the template is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined template
		if($ref_name eq "C Definein"){
			my $ref_file = $ref->file->longname();
			$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
			$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
			last;
		}
	}
	# only user-defined freestanding function templates in C++ files are processed
	next unless $is_user_def_template;
	next unless $defined_in_cpp;
	$func_temp_definitions ++;
	# to traverse the refs of this function template
	foreach my $ref ($func->refs()){
		my $ref_file = $ref->file()->longname();
		if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
			my $ref_name = $ref->kind()->longname();
			# if the function template is called
			if($ref_name eq "C Callby"){
				$func_temp_instantiations ++;
			}
		}
	}
}

sub process_class_templates{
	foreach my $class ($db->ents($_[0])){
		my $class_name = $class->longname;
		my $is_user_def_template = 1;
		my @metriclist = ("AltCountLineCode");
		my @value = $class->metric(@metriclist);
		# to determine whether it is a library template
		if(not defined($value[0])){
			next;
		}
		# to determine whether it is a 3rd-party template
		elsif($class_name =~ /($third_party_lib_prefix)/){
			$is_user_def_template = 0;
		}
		my $defined_in_cpp = 1;
		foreach my $ref ($class->refs()){
			my $ref_name = $ref->kind()->longname();
			# if the template is defined in 3rd-party file or not in C++ file, do not mark it as a user-defined template
			if($ref_name eq "C Definein"){
				my $ref_file = $ref->file->longname();
				$defined_in_cpp = 0 if $ref_file !~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/;
				$is_user_def_template = 0 if $ref_file =~ /($third_party_lib_path)/;
				last;
			}
		}
		# only user-defined class templates in C++ files are processed
		next unless $is_user_def_template;
		next unless $defined_in_cpp;
		$class_temp_definitions ++;
		# traverse the refs of this class template
		foreach my $ref ($class->refs()){
			my $ref_file = $ref->file()->longname();
			if($ref_file =~ /\.(C|cc|cpp|cxx|H|h|hh|hpp|hxx)$/ and $ref_file !~ /($third_party_lib_path)/){
				my $ref_name = $ref->kind()->longname();
				# process different kinds of refs
				if($ref_name eq "C Typedby" or $ref_name eq "C Useby" or $ref_name eq "C Inactive Useby" 
				or $ref_name eq "C Cast Useby" or $ref_name eq "C Nameby" or $ref_name eq "C Friendby"){
					$class_temp_instantiations ++;
				}
			}
		}
	}
}

# write info into excel
# ===============================================================================================================================================
my $output_path = $common_output_path.$proj_name."_BasicInfo_2.csv";
if(-e $output_path){
	unlink $output_path;
}
open("metricfile", ">>$output_path");
syswrite("metricfile", "class template definitions, class template instantiations, function template definitions, function template instantiations\n");
syswrite("metricfile", "$class_temp_definitions, //$class_temp_instantiations, //$func_temp_definitions, //$func_temp_instantiations\n");
close("metricfile");
